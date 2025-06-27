// Debugging setup
const debug = true;
const log = (message) => {
  if (debug) {
    chrome.storage.local.get(["logs"], (result) => {
      const logs = result.logs || [];
      logs.push(`${new Date().toISOString()}: ${message}`);
      chrome.storage.local.set({ logs });
    });
    console.log(message);
  }
};

// Create context menu
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "open-in-potplayer",
    title: "Open in PotPlayer",
    contexts: ["link"],
    targetUrlPatterns: [
      "*://*/*.mp4",
      "*://*/*.avi",
      "*://*/*.mkv",
      "*://*/*.mov",
      "*://*/*.flv",
      "*://*/*.wmv",
      "*://*/*.m3u8",
      "*://*/*.mpd",
      "*://*/*.webm",
    ],
  });
  log("Context menu created");
  checkNativeHost();
});

// Handle context menu clicks

chrome.contextMenus.onClicked.addListener((info) => {
  if (info.menuItemId === "open-in-potplayer") {
    log(`Attempting to open: ${info.linkUrl}`);

    // Test connection first
    chrome.runtime.sendNativeMessage(
      "com.potplayer.launcher",
      { test: "ping" },
      (pingResponse) => {
        if (chrome.runtime.lastError || !pingResponse) {
          const errorMsg = `Host unreachable: ${
            chrome.runtime.lastError?.message || "No response"
          }`;
          log(errorMsg);
          showError(
            "PotPlayer not responding. Check native host installation."
          );
          return;
        }

        // Send actual URL request
        chrome.runtime.sendNativeMessage(
          "com.potplayer.launcher",
          { url: info.linkUrl },
          (response) => {
            if (chrome.runtime.lastError || !response || response.error) {
              const err =
                response?.error ||
                chrome.runtime.lastError?.message ||
                "Unknown error";
              log(`Launch failed: ${err}`);
              showError(`Failed to launch: ${err}`);
            } else {
              log("PotPlayer launched successfully");
            }
          }
        );
      }
    );
  }
});

// UPDATED showError FUNCTION
function showError(message) {
  try {
    chrome.notifications.create({
      type: "basic",
      iconUrl: "assets/icons/icon16.png",
      title: "PotPlayer Error",
      message: message,
    });
  } catch (e) {
    console.error("Notification failed:", e);
  }
}

// Debugging functions
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "getLogs") {
    chrome.storage.local.get(["logs"], (result) => {
      chrome.runtime.sendMessage({ action: "logs", data: result.logs || [] });
    });
  } else if (request.action === "clearLogs") {
    chrome.storage.local.set({ logs: [] });
  } else if (request.action === "checkHost") {
    checkNativeHost();
    sendResponse({ status: "checking" });
  }
});

function checkNativeHost() {
  chrome.runtime.sendNativeMessage(
    "com.potplayer.launcher",
    { test: "ping" },
    (response) => {
      if (chrome.runtime.lastError) {
        chrome.storage.local.set({ hostInstalled: false });
        // Show installation prompt in popup
      } else {
        chrome.storage.local.set({ hostInstalled: true });
      }
    }
  );
}

function verifyHost(callback) {
  chrome.runtime.sendNativeMessage(
    "com.potplayer.launcher",
    { test: "ping" },
    (response) => {
      if (response && response.response === "pong") {
        callback(true);
      } else {
        callback(false);
      }
    }
  );
}

function isValidMediaUrl(url) {
  const mediaExtensions = /\.(mp4|mkv|avi|mov|wmv|flv|webm|m3u8)$/i;
  try {
    const parsed = new URL(url);
    return mediaExtensions.test(parsed.pathname);
  } catch {
    return false;
  }
}
