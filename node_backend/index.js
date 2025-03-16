const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const nodemailer = require('nodemailer');

const app = express();
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/skincareapp', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('Connected to MongoDB');
}).catch((err) => {
  console.error('Error connecting to MongoDB:', err);
});

// User Schema and Model
const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
});

const User = mongoose.model('User', userSchema);

// Register Route
app.post('/register', async (req, res) => {
  const { username, email, password } = req.body;

  try {
    // Check if the email already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    // Hash the password before saving it in the database
    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = new User({ username, email, password: hashedPassword });
    await newUser.save();

    res.status(201).json({ message: 'User registered successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Forgot Password Route
app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Generate a reset token (for simplicity, using JWT)
    const resetToken = jwt.sign({ id: user._id }, 'your_jwt_secret', { expiresIn: '15m' });

    // Send reset link via email (using Nodemailer)
    const transporter = nodemailer.createTransport({
      service: 'Gmail',
      auth: {
        user: 'urpersonalizedskincareadvisor@gmail.com',
        pass: 'flpm tkaz zmtw dbpl',
      },
    });

    const mailOptions = {
      from: 'urpersonalizedskincareadvisor@gmail.com',
      to: email,
      subject: 'Password Reset Request',
      text: `You requested a password reset. Click the link below to reset your password:\n\nhttp://localhost:3000/reset-password/${resetToken}`,
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({ message: 'Password reset link sent to your email' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Login Route
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ error: 'Invalid credentials' });

    // Compare passwords
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ error: 'Invalid credentials' });

    // Generate JWT Token
    const token = jwt.sign({ id: user._id }, 'your_jwt_secret', { expiresIn: '1h' });
    res.json({ message: 'Login successful', token });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/protected', (req, res) => {
    const token = req.headers['authorization'];
    if (!token) return res.status(401).json({ error: 'Access denied' });
  
    try {
      const verified = jwt.verify(token.split(' ')[1], 'your_jwt_secret');
      res.json({ message: 'Access granted', userId: verified.id });
    } catch (err) {
      res.status(400).json({ error: 'Invalid token' });
    }
  });
 
  app.patch('/update-profile', async (req, res) => {
    const token = req.headers['authorization'];
    if (!token) return res.status(401).json({ error: 'Access denied' });
  
    try {
      const decoded = jwt.verify(token.split(' ')[1], 'your_jwt_secret');
      const { username, email, password } = req.body;
  
      // Validate input data
      if (!username || !email || !password) {
        return res.status(400).json({ error: 'All fields are required' });
      }
  
      // Update user document in MongoDB
      await User.findByIdAndUpdate(decoded.id, {
        username,
        email,
        password: await bcrypt.hash(password, 10),
      });
  
      res.status(200).json({ message: 'Profile updated successfully' });
    } catch (err) {
      console.error(err);
      res.status(400).json({ error: 'Invalid token or server error' });
    }
  });  

  app.post('/logout', async (req, res) => {
    try {
      // Clear the JWT token by setting an expired cookie
      res.cookie('jwt', '', { maxAge: 1 });
      
      res.status(200).json({ message: 'Logged out successfully' });
    } catch (error) {
      console.error('Error during logout:', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });
  
// Start Server
const PORT = 3000;
app.listen(PORT, () => console.log(`Node.js server running on http://localhost:${PORT}`));
