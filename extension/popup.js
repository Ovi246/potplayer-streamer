// Modern PotPlayer Opener Popup Script

const INSTALLER_URL = "https://yourdomain.com/host-installer.zip"; // Update this to your actual installer URL

function renderInstallPrompt() {
  const content = document.getElementById("content");
  content.innerHTML = `
    <div class="install-prompt">
      <svg width="48" height="48" fill="none" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#f5c518"/><path d="M12 8v4" stroke="#222" stroke-width="2" stroke-linecap="round"/><circle cx="12" cy="16" r="1" fill="#222"/></svg>
      <h2>Native Host Not Installed</h2>
      <p>
        To use this extension, install the PotPlayer Native Host.<br>
        <b>1.</b> <a href="${INSTALLER_URL}" target="_blank">Download the installer</a><br>
        <b>2.</b> Extract and run <code>install.bat</code> as Administrator.<br>
        <b>3.</b> Click below to check again.
      </p>
      <button id="check-install" class="primary">Check Again</button>
    </div>
  `;
  document.getElementById("check-install").onclick = () => {
    chrome.runtime.sendMessage({ action: "checkHost" }, () => {
      setTimeout(updateUI, 1000);
    });
  };
}

function renderReady() {
  const content = document.getElementById("content");
  content.innerHTML = `
    <div class="ready">
      <svg width="48" height="48" fill="none" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#4caf50"/><path d="M8 12l2.5 2.5L16 9" stroke="#fff" stroke-width="2" stroke-linecap="round"/></svg>
      <h2>PotPlayer Opener Ready</h2>
      <p>Right-click a video link and choose <b>Open in PotPlayer</b>.</p>
      <div class="actions">
        <button id="view-logs">View Logs</button>
        <button id="clear-logs">Clear Logs</button>
      </div>
      <pre id="logs" class="logs"></pre>
    </div>
  `;
  document.getElementById("view-logs").onclick = () => {
    chrome.runtime.sendMessage({ action: "getLogs" });
  };
  document.getElementById("clear-logs").onclick = () => {
    chrome.runtime.sendMessage({ action: "clearLogs" });
    document.getElementById("logs").textContent = "";
  };
}

function updateUI() {
  chrome.storage.local.get(["hostInstalled"], (result) => {
    if (result.hostInstalled) {
      renderReady();
    } else {
      renderInstallPrompt();
    }
  });
}

chrome.runtime.onMessage.addListener((msg) => {
  if (msg.action === "logs") {
    document.getElementById("logs").textContent = (msg.data || []).join("\n");
  }
});

document.addEventListener("DOMContentLoaded", updateUI);
