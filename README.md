# BitHuB Jaipur (Development / Backup)

This repository serves as the **Development Sandbox and Backup Environment** for the BitHuB Jaipur campus. It contains both the React frontend source code and the Node.js backend.

## 🚀 Environments

- **Frontend Development Site:** [https://bithub-jaipur-development-front.onrender.com/](https://bithub-jaipur-development-front.onrender.com/)
- **Backend Development API:** [https://bithub-jaipur-development.onrender.com](https://bithub-jaipur-development.onrender.com)

## 🛠️ Workflows & Rules

1. **Development & Bug Fixes:** All new features, bug fixes, and architectural experiments should happen here first. 
2. **Branching:** Mid-development work should be pushed to branches like `bit_jaipur`.
3. **Deployments:** Pushing or merging code into the `main` branch of this repository will **automatically trigger a redeploy** to the Render development environments (typically takes 50-120 seconds).
4. **Moving to Production:** Once features are tested and stable here, they should be synced and pushed to the official Production repository (`ananttheacharya/BitHub-Jaipur`) for the backend, or submitted as a PR to the official Frontend fork (`ananttheacharya/BitHubv2`) for the frontend.

## 📁 Repository Structure
- `Front-End New/`: The active development folder for the React Vite frontend.
- `Backend/`: The Node/Express backend codebase.
- `Study Material/`: PDF and reference materials served by the backend.

*(Please read `context.md` for exhaustive architectural details and command workflows).*
