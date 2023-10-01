const express = require("express");
const bodyParser = require("body-parser");
const admin = require("firebase-admin");
const multer = require("multer");
const { Storage } = require("@google-cloud/storage");

const app = express();
const port = 3000;
app.use(bodyParser.json());

// Initialize Firebase Admin  with  service account credentials
const serviceAccount = require("./flutter-app-6ac89-firebase-adminsdk-gnlhn-39cc22762c");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://flutter-app-6ac89.firebaseio.com",
});

const storage = new Storage({
  keyFilename: "./flutter-app-6ac89-firebase-adminsdk-gnlhn-39cc22762c.json",
});

const bucket = storage.bucket("gs://flutter-app-6ac89.appspot.com"); //firebase app name

// Set up multer storage for file uploads
const multerStorage = multer.memoryStorage();
const upload = multer({ storage: multerStorage });

// Add a product to Firestore and upload the image to Firebase Storage

app.post("/addproduct", upload.single("image"), async (req, res) => {
  try {
    const { name, price, description } = req.body;
    const imageFile = req.file;

    const imageFileName = `${Date.now()}_${imageFile.originalname}`;
    const file = bucket.file(imageFileName);
    const stream = file.createWriteStream({
      metadata: {
        contentType: imageFile.mimetype,
      },
    });

    stream.on("error", (error) => {
      console.error("Error uploading image:", error);
      res.status(500).json({ message: "Image upload failed" });
    });

    stream.on("finish", async () => {
      try {
        const publicUrl = await file.getSignedUrl({
          action: "read",
          expires: "01-01-2100",
        });

        // Add product data to Firestore
        const productRef = admin.firestore().collection("products").doc();
        await productRef.set({
          name,
          price: price,
          description,
          imageUrl: publicUrl[0],
        });

        res.status(200).json({ message: "Product added successfully" });
      } catch (error) {
        console.error("Error getting image URL:", error);
        res.status(500).json({ message: "Image URL retrieval failed" });
      }
    });

    stream.end(imageFile.buffer);
  } catch (error) {
    console.error("Add product error:", error);
    res.status(500).json({ message: "Product addition failed" });
  }
});

// GET list of products
app.get("/products", async (req, res) => {
  try {
    const snapshot = await admin.firestore().collection("products").get();
    const products = snapshot.docs.map((doc) => doc.data());
    res.json(products);
  } catch (error) {
    console.error("Error fetching products:", error);
    res.status(500).json({ message: "Failed to fetch products" });
  }
});

// login
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    const user = await admin
      .firestore()
      .collection("users")
      .doc(userRecord.uid)
      .get();

    if (userRecord.password == user.password) {
      const userData = await admin
        .firestore()
        .collection("users")
        .doc(userRecord.uid)
        .get();
      const userRole = userData.data()?.role;

      res.status(200).json({ message: "Login successful", role: userRole });
    } else {
      res.status(401).json({ message: "Incorrect password" });
    }
  } catch (error) {
    console.error("Login error:", error);
    res.status(401).json({ message: "Login failed" });
  }
});

//create users
app.post("/signup", async (req, res) => {
  const userData = req.body;
  try {
    // Create user in Firebase Authentication
    const user = await admin.auth().createUser({
      email: userData.email,
      password: userData.password,
    });

    // in Firestore
    await admin.firestore().collection("users").doc(user.uid).set({
      email: userData.email,
      password: userData.password,
      role: userData.role,
    });

    res.status(200).json({ message: "User registered successfully" });
  } catch (error) {
    console.error("Registration error:", error);
    res.status(500).json({ message: "Registration failed" });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
