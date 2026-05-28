# 🚀 Free Deployment Guide for Bloom Filter Project

This guide covers multiple free deployment options for your Bloom Filter application.

## 📋 **Project Overview**
- **Backend**: Pure Lua server with Redis storage
- **Frontend**: Static HTML/CSS/JavaScript files
- **Dependencies**: Redis, Lua, Node.js

## 🎯 **Recommended Deployment Options**

### **Option 1: Railway (Recommended)**
**Cost**: Free tier with 500 hours/month

**Why Railway?**
- ✅ Supports Lua applications
- ✅ Built-in Redis addon
- ✅ Automatic HTTPS
- ✅ Easy GitHub integration
- ✅ Good free tier limits

**Steps:**
1. Push code to GitHub
2. Go to [Railway.app](https://railway.app)
3. Connect your GitHub repository
4. Add Redis service
5. Deploy your application

### **Option 2: Render**
**Cost**: Free tier available

**Why Render?**
- ✅ Static site hosting for frontend
- ✅ Web service for backend
- ✅ Redis addon available
- ✅ Automatic deployments

**Steps:**
1. Push code to GitHub
2. Go to [Render.com](https://render.com)
3. Create two services:
   - Static Site (frontend)
   - Web Service (backend)
4. Add Redis addon

### **Option 3: Vercel + Railway (Hybrid)**
**Cost**: Both have free tiers

**Why Hybrid?**
- ✅ Vercel excels at static hosting
- ✅ Railway handles backend + Redis well
- ✅ Best performance for each component

**Steps:**
1. Deploy frontend to Vercel
2. Deploy backend + Redis to Railway
3. Update frontend API URLs

## 🔧 **Deployment Files Created**

### **Railway Configuration**
- `railway.json` - Railway deployment config
- `Procfile` - Process definition

### **Vercel Configuration**
- `vercel.json` - Vercel static site config

### **Docker Support**
- `Dockerfile` - Container configuration

## 📝 **Step-by-Step Deployment**

### **Railway Deployment (Easiest)**

1. **Prepare your code:**
   ```bash
   # Ensure all files are committed
   git add .
   git commit -m "Add deployment configuration"
   git push origin main
   ```

2. **Deploy to Railway:**
   - Go to [Railway.app](https://railway.app)
   - Sign up with GitHub
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository
   - Add Redis service
   - Deploy!

3. **Configure environment:**
   - Set `PORT` environment variable to `8080`
   - Railway will provide Redis connection details

### **Vercel + Railway (Best Performance)**

1. **Deploy Backend to Railway:**
   - Follow Railway steps above
   - Note the backend URL (e.g., `https://your-app.railway.app`)

2. **Deploy Frontend to Vercel:**
   ```bash
   # Install Vercel CLI
   npm i -g vercel
   
   # Deploy frontend
   cd frontend
   vercel --prod
   ```

3. **Update API URLs:**
   - Update frontend to use Railway backend URL
   - Redeploy frontend

## 🌐 **Environment Variables**

### **Backend (Railway)**
```
PORT=8080
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
```

### **Frontend (Vercel)**
```
VITE_API_URL=https://your-backend.railway.app
```

## 🔍 **Testing Your Deployment**

1. **Test Backend:**
   ```bash
   curl https://your-backend.railway.app/api/bloom-filter/list
   ```

2. **Test Frontend:**
   - Visit your frontend URL
   - Upload a test file
   - Create a bloom filter
   - Test search functionality

## 📊 **Free Tier Limits**

### **Railway**
- 500 hours/month
- 1GB RAM
- 1GB storage
- 100GB bandwidth

### **Vercel**
- 100GB bandwidth
- Unlimited static sites
- 100 serverless functions

### **Render**
- 750 hours/month
- 512MB RAM
- 1GB storage

## 🚨 **Important Notes**

1. **Redis Persistence**: Free tiers may not persist data between restarts
2. **Cold Starts**: Serverless functions may have cold start delays
3. **Rate Limits**: Free tiers have request rate limits
4. **Monitoring**: Set up basic monitoring for production use

## 🔧 **Troubleshooting**

### **Common Issues:**

1. **Redis Connection Failed:**
   - Check Redis service is running
   - Verify connection details
   - Check firewall settings

2. **Frontend Can't Connect to Backend:**
   - Verify CORS settings
   - Check API URLs
   - Ensure backend is running

3. **File Upload Issues:**
   - Check file size limits
   - Verify content-type headers
   - Check timeout settings

## 📈 **Scaling Up**

When you outgrow free tiers:

1. **Railway Pro**: $5/month for more resources
2. **Vercel Pro**: $20/month for more bandwidth
3. **Render Paid**: $7/month for more resources

## 🎉 **Success!**

Your Bloom Filter application should now be deployed and accessible worldwide!

**Next Steps:**
- Set up custom domain (optional)
- Configure monitoring
- Set up CI/CD pipeline
- Add SSL certificates (usually automatic)

---

**Need Help?**
- Check platform documentation
- Review error logs
- Test locally first
- Contact platform support
