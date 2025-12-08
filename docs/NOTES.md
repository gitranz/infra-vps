# Additional Notes and Considerations
...
# vscode Github Project
used repo:
https://github.com/linuxserver/docker-code-server


# Installation of every ai code cli npm package installation on sudo user

Below is a **copy-pasteable step-by-step command list** for installing the **Gemini CLI** under a regular sudo-capable user, using a **user-local npm global directory** so you can run `gemini` **without sudo**.

I’ll assume:

* You’re logged in as a non-root user (with sudo rights).
* Node.js (v18+) and npm are already installed. If not, I include a Node install option too.

---

## 1️⃣ (Optional) Install Node.js LTS via NodeSource

If you *don’t* have a recent Node:

```bash
# As your sudo-capable user
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Check versions:

```bash
node -v
npm -v
```

You want **Node ≥ 18** for the Gemini CLI.

---

## 2️⃣ Create a user-local npm global directory

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
```

This tells npm: “install global packages into `~/.npm-global`, not into a root-owned system path.”

---

## 3️⃣ Add the npm-global bin path to your shell

For Bash:

```bash
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

For Zsh (if you’re using it):

```bash
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify it’s in your path:

```bash
echo $PATH
```

You should see something like:

```text
/home/you/.npm-global/bin:...
```

---

## 4️⃣ Install Gemini CLI *without sudo*

Now you install the CLI as your normal user:

```bash
npm install -g @google/gemini-cli
```

Because of the prefix, this writes into `~/.npm-global` and doesn’t need `sudo`.

Check that it’s installed:

```bash
gemini --help
```

If that prints usage info, you’re good.

---

## 5️⃣ Authenticate Gemini CLI (first run)

Two main options:

### a) Using your Google account (OAuth)

```bash
gemini login
```

This will print a URL; open it in your browser, log into the Google account you use for Gemini / AI Studio, approve, then paste the verification code back into the terminal if prompted.

### b) Using an API key (from Google AI Studio)

1. Go to Google AI Studio.
2. Create / copy an API key.
3. Set it in your shell:

```bash
export GEMINI_API_KEY="YOUR_API_KEY_HERE"
```

To make this persistent (bash):

```bash
echo 'export GEMINI_API_KEY="YOUR_API_KEY_HERE"' >> ~/.bashrc
source ~/.bashrc
```

---

## 6️⃣ Quick sanity test

Run a simple prompt:

```bash
gemini chat "Say hello from the command line."
```

Or use the interactive mode:

```bash
gemini chat
```

You should now be interacting with Gemini, **no sudo involved**, CLI fully isolated to your user.

---

## 7️⃣ Mini “I messed up and used sudo” recovery

If at some point you *did* run `sudo npm install -g @google/gemini-cli` and things are weird:

```bash
# Remove root-level global install (not strictly universal, but common)
sudo npm uninstall -g @google/gemini-cli

# Make sure your user-local setup is used instead
npm config set prefix ~/.npm-global
npm install -g @google/gemini-cli
```

Then check:

```bash
which gemini
```

It should point into `~/.npm-global/bin/gemini`.

---

This setup scales nicely: same npm-global directory will also hold `claude`, `codex`, etc., with zero sudo and minimal permission drama.
