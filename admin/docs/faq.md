# Frequently Asked Questions

## General Questions

### What is N.O.M.A.D.?
N.O.M.A.D. (Node for Offline Media, Archives, and Data) is a personal server that gives you access to knowledge, education, and AI assistance without requiring an internet connection. It runs on your own hardware, keeping your data private and accessible anytime.

### Do I need internet to use N.O.M.A.D.?
No — that's the whole point. Once your content is downloaded, everything works offline. You only need internet to:
- Download new content
- Update the software
- Sync the latest versions of Wikipedia, maps, etc.

### What hardware do I need?
N.O.M.A.D. runs on macOS and is designed for capable hardware, especially if you want to use the AI features. Recommended:
- **Apple Silicon (M1/M2/M3/M4)** — strongly recommended for AI performance (unified memory = fast inference)
- 16GB+ RAM (32GB+ for best AI performance; on Apple Silicon this is unified memory shared with the GPU)
- SSD storage (size depends on content — 500GB minimum, 2TB+ recommended)
- macOS 12 Monterey or later
- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) installed and running

**For detailed build recommendations at three price points ($200–$800+), see the [Hardware Guide](https://www.projectnomad.us/hardware).**

### How much storage do I need?
It depends on what you download:
- Full Wikipedia: ~95GB
- Khan Academy courses: ~50GB
- Medical references: ~500MB
- US state maps: ~2-3GB each
- AI models: 10-40GB depending on model

Start with essentials and add more as needed.

---

## Content Questions

### How do I add more Wikipedia content?
1. Go to **Settings** (hamburger menu → Settings)
2. Click **Content Explorer**
3. Browse available Wikipedia packages
4. Click Download on items you want

You can also use the **Content Explorer** to browse all available ZIM content beyond Wikipedia.

### How do I add more educational courses?
1. Open **Kolibri**
2. Sign in as an admin
3. Go to **Device → Channels**
4. Browse and import available channels

### How current is the content?
Content is as current as when it was last downloaded. Wikipedia snapshots are typically updated monthly. Check the file names or descriptions for dates.

### Can I add my own files?
Yes — with the Knowledge Base. Upload PDFs, text files, and other documents to the [Knowledge Base](/knowledge-base), and the AI can reference them when answering your questions. This uses semantic search to find relevant information from your uploaded files.

For Kiwix content, N.O.M.A.D. uses standard ZIM files. For educational content, Kolibri uses its own channel format.

### What are curated collection tiers?
When selecting content in the Easy Setup wizard or Content Explorer, collections are organized into three tiers:
- **Essential** — Core content for the category (smallest download)
- **Standard** — Essential plus additional useful content
- **Comprehensive** — Everything available for the category (largest download)

This helps you balance content coverage against storage usage.

---

## AI Questions

### How do I use the AI chat?
1. Go to [AI Chat](/chat) from the Command Center
2. Type your question or request
3. The AI responds in conversational style

The AI must be installed first — enable it during Easy Setup or install it from the [Apps](/settings/apps) page.

### How do I upload documents to the Knowledge Base?
1. Go to **[Knowledge Base →](/knowledge-base)**
2. Upload your documents (PDFs, text files, etc.)
3. Documents are processed and indexed automatically
4. Ask questions in AI Chat — the AI will reference your uploaded documents when relevant

You can also remove documents from the Knowledge Base when they're no longer needed.

NOMAD documentation is automatically added to the Knowledge Base when the AI Assistant is installed.

### What is the System Benchmark?
The System Benchmark tests your hardware performance and generates a NOMAD Score — a weighted composite of CPU, memory, disk, and AI performance. You can create a Builder Tag (a NOMAD-themed identity like "Tactical-Llama-1234") and share your results with the [community leaderboard](https://benchmark.projectnomad.us).

Go to **[System Benchmark →](/settings/benchmark)** to run one.

### What is the Early Access Channel?
The Early Access Channel lets you opt in to receive release candidate builds with the latest features and improvements before they hit stable releases. You can enable or disable it from **Settings → Check for Updates**. Early access builds may contain bugs — if you prefer stability, stay on the stable channel.

---

## Troubleshooting

### A feature isn't loading or shows a blank page

**Try these steps:**
1. Wait 30 seconds — some features take time to start
2. Refresh the page (Ctrl+R or Cmd+R)
3. Go back to the Command Center and try again
4. Check Settings → System to see if the service is running
5. Try restarting the service (Stop, then Start in Apps manager)

### Maps show a gray/blank area

The Maps feature requires downloaded map data. If you see a blank area:
1. Go to **Settings → Maps Manager**
2. Download map regions for your area
3. Wait for downloads to complete
4. Return to Maps and refresh

### AI responses are slow

Local AI requires significant computing power. To improve speed:
- **Hardware Acceleration** — Apple Silicon Macs utilize the Metal framework natively, improving AI speed dramatically over CPU execution.
- Close other applications on the server
- Ensure adequate cooling (overheating causes throttling)
- Consider using a smaller/faster AI model if available

### How do I enable GPU acceleration for AI?

On macOS, AI performance is determined primarily by how many resources Docker Desktop is allowed to use. To get the best performance:

1. Open **Docker Desktop → Settings → Resources**
2. Set **Memory** to at least 8GB (16GB+ recommended for large models)
3. Set **CPUs** to at least 4
4. Click **Apply & Restart**
5. In N.O.M.A.D., go to **Apps**, find the **AI Assistant**, and click **Force Reinstall** to apply the new resource settings

**Apple Silicon note:** Ollama runs inside a Docker container on macOS, which means it uses CPU threads allocated to Docker rather than the Metal GPU directly. For the absolute best AI performance on Apple Silicon, more CPU cores and memory allocated to Docker Desktop makes the biggest difference.

**Tip:** Run a [System Benchmark](/settings/benchmark) before and after increasing Docker Desktop resources to measure the improvement.

### My Mac went to sleep and N.O.M.A.D. stopped working

When macOS sleeps, Docker Desktop suspends and all N.O.M.A.D. containers stop. After waking:

1. Wait 30–60 seconds for Docker Desktop to resume
2. Refresh the browser at `http://localhost:8080`
3. If it doesn't come back, restart services from the terminal:
```bash
sudo bash ~/project-nomad/start_nomad.sh
```

To prevent this, go to **System Settings → Energy Saver** and disable "Put hard disks to sleep when possible" and set display sleep to a longer interval.

### I updated Docker Desktop resources but AI is still slow

After changing CPU/Memory in Docker Desktop Settings → Resources:

1. Go to **Apps**
2. Find the **AI Assistant** and click **Force Reinstall**

The container needs to be recreated to pick up the new resource limits.

### AI Chat not available

The AI Chat page requires the AI Assistant to be installed first:
1. Go to **[Apps](/settings/apps)**
2. Install the **AI Assistant**
3. Wait for the installation to complete
4. The AI Chat will then be accessible from the home screen or [Chat](/chat)

### Knowledge Base upload stuck

If a document upload appears stuck in the Knowledge Base:
1. Check that the AI Assistant is running in **Settings → Apps**
2. Large documents take time to process — wait a few minutes
3. Try uploading a smaller document to verify the system is working
4. Check **Settings → System** for any error messages

### Benchmark won't submit to leaderboard

To share results with the community leaderboard:
- You must run a **Full Benchmark** (not System Only or AI Only)
- The benchmark must include AI results (AI Assistant must be installed and working)
- Your score must be higher than any previous submission from the same hardware

If submission fails, check the error message for details.

### "Service unavailable" or connection errors

The service might still be starting up. Wait 1-2 minutes and try again.

If the problem persists:
1. Go to **Settings → Apps**
2. Find the problematic service
3. Click **Restart**
4. Wait 30 seconds, then try again

### Downloads are stuck or failing

1. Check your internet connection
2. Go to **Settings** and check available storage
3. If storage is full, delete unused content
4. Cancel the stuck download and try again

### The server won't start

If you can't access the Command Center at all:
1. Make sure **Docker Desktop is running** — look for the Docker whale icon in your Mac menu bar. N.O.M.A.D. cannot run without it.
2. Open Docker Desktop and check that all containers are shown as running
3. Try starting services manually:
```bash
sudo bash ~/project-nomad/start_nomad.sh
```
4. Check network connectivity and try `http://localhost:8080`
5. If Docker Desktop shows errors, restart it from the menu bar icon

### Docker Desktop says it doesn't have enough memory

If Docker Desktop is showing memory pressure or containers are crashing:
1. Open **Docker Desktop → Settings → Resources**
2. Increase **Memory** to at least 8GB
3. Click **Apply & Restart**
4. Wait for Docker to restart, then refresh N.O.M.A.D. at `http://localhost:8080`

### My firewall is blocking N.O.M.A.D.

If other devices on your network can't reach N.O.M.A.D.:
1. Go to **System Settings → Network → Firewall**
2. Click **Options** and check that Docker is allowed to accept incoming connections
3. If not listed, click the `+` button and add Docker Desktop

Alternatively, open the specific ports (8080, 8090, 8300, etc.) for your local network interface.

### I forgot my Kolibri password

Kolibri passwords are managed separately:
1. If you're an admin, you can reset user passwords in Kolibri's user management
2. If you forgot the admin password, you may need to reset it via command line (contact your administrator)

---

## Updates and Maintenance

### How do I update N.O.M.A.D.?
1. Go to **Settings → Check for Updates**
2. If an update is available, click to install
3. The system will download updates and restart automatically
4. This typically takes 2-5 minutes

### Should I update regularly?
Yes, while you have internet access. Updates include:
- Bug fixes
- New features
- Security improvements
- Performance enhancements

### How do I update content (Wikipedia, etc.)?
Content updates are separate from software updates:
1. Go to **Settings → Content Manager** or **Content Explorer**
2. Check for newer versions of your installed content
3. Download updated versions as needed

Tip: New Wikipedia snapshots are released approximately monthly.

### What happens if an update fails?
The system is designed to recover gracefully. If an update fails:
1. The previous version should continue working
2. Try the update again later
3. Check Settings → System for error messages

### Command-Line Maintenance

For advanced troubleshooting or when you can't access the web interface, N.O.M.A.D. includes helper scripts in `~/project-nomad`:

**Start all services:**
```bash
sudo bash ~/project-nomad/start_nomad.sh
```

**Stop all services:**
```bash
sudo bash ~/project-nomad/stop_nomad.sh
```

**Update Command Center:**
```bash
sudo bash ~/project-nomad/update_nomad.sh
```
*Note: This updates the Command Center only, not individual apps. Update apps through the web interface.*

**Uninstall N.O.M.A.D.:**
```bash
curl -fsSL https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/uninstall_nomad.sh -o uninstall_nomad.sh
sudo bash uninstall_nomad.sh
```
*Warning: This cannot be undone. All data will be deleted.*

---

## Privacy and Security

### Is my data private?
Yes. N.O.M.A.D. runs entirely on your hardware. Your searches, AI conversations, and usage data never leave your server.

### Can others access my server?
By default, N.O.M.A.D. is accessible on your local network. Anyone on the same network can access it. For public networks, consider additional security measures.

### Does the AI send data anywhere?
No. The AI runs completely locally. Your conversations are not sent to any external service. The AI chat is built into the Command Center — there's no separate service to configure.

---

## Getting More Help

### The AI can help
Try asking a question in [AI Chat](/chat). The local AI can answer questions about many topics, including technical troubleshooting. If you've uploaded NOMAD documentation to the Knowledge Base, it can also help with NOMAD-specific questions.

### Check the documentation
You're in the docs now. Use the menu to find specific topics.

### Join the community
Project N.O.M.A.D. is built for the community — by people who believe that knowledge and tools should be accessible to everyone, online or off.

- **Discord:** Get help, share your builds, and connect with other NOMAD users — **[Join the Community](https://discord.com/invite/crosstalksolutions)**
- **X / Twitter:** Follow **[@KhalilNoaman](https://x.com/KhalilNoaman)** for updates, development news, and community highlights

### Release Notes
See what's changed in each version: **[Release Notes](/docs/release-notes)**
