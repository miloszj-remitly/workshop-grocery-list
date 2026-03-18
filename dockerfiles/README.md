# Dockerfile Examples - Progressive Learning Guide

This directory contains 7 Dockerfile examples, progressing from simplest to most advanced. Each example builds upon the previous one, introducing new concepts and best practices.

## 📚 Examples Overview

### 1️⃣ Simple "Fat" Dockerfile (`01-simple-fat.Dockerfile`)
**Difficulty:** Beginner  
**Image Size:** ~800MB  
**Build Time:** Slow (no caching)

The most basic approach - everything in one stage, copied at once.

```bash
docker build -f dockerfiles/01-simple-fat.Dockerfile -t grocery-app:fat .
```

**When to use:** Quick prototypes, learning Docker basics

---

### 2️⃣ Layer Caching Optimization (`02-layer-caching.Dockerfile`)
**Difficulty:** Beginner  
**Image Size:** ~800MB  
**Build Time:** Fast (with cache)

Introduces layer caching by separating dependency installation from code copying.

```bash
docker build -f dockerfiles/02-layer-caching.Dockerfile -t grocery-app:cached .
```

**When to use:** Development, when you need build tools in the image

---

### 3️⃣ Multi-Stage Build (`03-multi-stage.Dockerfile`)
**Difficulty:** Intermediate  
**Image Size:** ~15MB  
**Build Time:** Fast (with cache)

Separates build and runtime stages for smaller, more secure images.

```bash
docker build -f dockerfiles/03-multi-stage.Dockerfile -t grocery-app:multi-stage .
```

**When to use:** Most production applications, good balance of size and debuggability

---

### 4️⃣ Distroless Base (`04-distroless.Dockerfile`)
**Difficulty:** Intermediate  
**Image Size:** ~10MB  
**Build Time:** Fast (with cache)

Uses Google's distroless images for maximum security.

```bash
docker build -f dockerfiles/04-distroless.Dockerfile -t grocery-app:distroless .
```

**When to use:** High-security production environments, when you don't need shell access

---

### 5️⃣ Scratch Base (`05-scratch.Dockerfile`)
**Difficulty:** Advanced  
**Image Size:** ~5-8MB  
**Build Time:** Fast (with cache)

Minimal possible image using scratch base - only your binary.

```bash
docker build -f dockerfiles/05-scratch.Dockerfile -t grocery-app:scratch .
```

**When to use:** Extreme size optimization, maximum security, stateless services

---

### 6️⃣ Production-Ready (`06-production-ready.Dockerfile`)
**Difficulty:** Advanced  
**Image Size:** ~15MB  
**Build Time:** Fast (with cache)

Complete production setup with security hardening, health checks, and best practices.

```bash
docker build -f dockerfiles/06-production-ready.Dockerfile -t grocery-app:production .
```

**When to use:** Production deployments, when you need all best practices

---

### 7️⃣ Debug Variant (`07-debug-variant.Dockerfile`)
**Difficulty:** Advanced  
**Image Size:** ~15-20MB (varies)  
**Build Time:** Fast (with cache)

Flexible build with debug/production modes using build arguments.

```bash
# Production build
docker build -f dockerfiles/07-debug-variant.Dockerfile -t grocery-app:prod .

# Debug build
docker build -f dockerfiles/07-debug-variant.Dockerfile --build-arg DEBUG=true -t grocery-app:debug .
```

**When to use:** When you need both debug and production builds from same Dockerfile

---

## 🎯 Quick Comparison

| Example | Size | Security | Debug | Complexity | Use Case |
|---------|------|----------|-------|------------|----------|
| 01-simple-fat | 800MB | ⭐ | ⭐⭐⭐⭐⭐ | ⭐ | Learning |
| 02-layer-caching | 800MB | ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | Development |
| 03-multi-stage | 15MB | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | Production |
| 04-distroless | 10MB | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐ | High Security |
| 05-scratch | 5-8MB | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ | Minimal Size |
| 06-production-ready | 15MB | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | Production |
| 07-debug-variant | 15-20MB | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Flexible |

---

## 🧪 Testing the Images

Run any built image:
```bash
docker run -p 8080:8080 grocery-app:TAG
```

Test the API:
```bash
curl http://localhost:8080/health
```

Compare image sizes:
```bash
docker images | grep grocery-app
```

---

## 📖 Key Concepts Learned

### Layer Caching
- Copy files that change less frequently first (go.mod, go.sum)
- Copy source code last
- Each RUN, COPY, ADD creates a new layer

### Multi-Stage Builds
- Separate build and runtime environments
- Only copy necessary artifacts to final image
- Dramatically reduces image size

### Static Binaries
- `CGO_ENABLED=0` creates static binaries
- No C library dependencies
- Portable across different Linux distributions

### Security Best Practices
- Run as non-root user
- Minimal base images
- Only include necessary dependencies
- Regular security scanning

### Build Optimization
- `-ldflags="-w -s"` strips debug info and symbol table
- Reduces binary size by ~30%
- Use for production builds

---

## 🚀 Recommended Path

1. **Start with:** `01-simple-fat.Dockerfile` - Understand basics
2. **Learn caching:** `02-layer-caching.Dockerfile` - Speed up builds
3. **Go multi-stage:** `03-multi-stage.Dockerfile` - Reduce size
4. **Production:** `06-production-ready.Dockerfile` - Best practices
5. **Advanced:** Explore `04`, `05`, `07` based on specific needs

---

## 💡 Tips

- Always use multi-stage builds for production
- Layer caching is crucial for fast development
- Smaller images = faster deployments, better security
- Non-root users are essential for security
- Health checks help orchestrators manage your containers

---

## 🔗 Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [Go Docker Best Practices](https://docs.docker.com/language/golang/build-images/)

