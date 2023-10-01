FROM node:17-alpine

# Create app directory 
WORKDIR C:\Users\Abdullah\Desktop\flutter app\backend

COPY package*.json ./

RUN npm install 

# Copy source code to container
COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
