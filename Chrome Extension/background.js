// background.js

let slogBlockerSettings = localStorage.getItem("slogBlockerSettings");
if (!slogBlockerSettings) {
  slogBlockerSettings = {
    users: [],
    addAvatarTooltips: false,
    moveUserBylines: true,
    addTopPagination: true,
    addCommentLinks: true,
  };

  localStorage.setItem(
    "slogBlockerSettings",
    JSON.stringify(slogBlockerSettings)
  );
}

chrome.runtime.onMessage.addListener(function (request, sender, sendResponse) {
  if (request.message === "DOMContentLoaded") {
    sendMessageToTab("filterComments", sender.tab);
  } else if (request.message === "slogBlockerSettingsChanged") {
    broadcastMessage("settingsUpdated");
  } else if (request.message === "openSettings") {
    chrome.tabs.create({ url: request.url });
  } else if (
    request.message === "blockUser" ||
    request.message == "changeAvatar"
  ) {
    updateBlockerSettingsWithUserInfo(request.userInfo);
    broadcastMessage("settingsUpdated");
  }
  return true;
});

chrome.browserAction.onClicked.addListener(function (tab) {
  chrome.runtime.openOptionsPage();
});

function sendMessageToActiveTab(message) {
  chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
    sendMessageToTab(message, tabs[0]);
  });
}

function sendMessageToTab(message, tab) {
  chrome.tabs.sendMessage(tab.id, {
    message: message,
    appInfo: JSON.parse(localStorage.getItem("slogBlockerSettings")),
  });
}

function broadcastMessage(message) {
  const appInfo = JSON.parse(localStorage.getItem("slogBlockerSettings"));
  const manifest = chrome.runtime.getManifest();
  manifest.content_scripts.forEach((element) => {
    chrome.tabs.query({ url: element.matches }, function (tabs) {
      tabs.forEach((tab) => {
        chrome.tabs.sendMessage(tab.id, {
          message: message,
          appInfo: appInfo,
        });
      });
    });
  });
}

function updateBlockerSettingsWithUserInfo(userInfo) {
  let settings = JSON.parse(localStorage.getItem("slogBlockerSettings"));
  let userIndex = settings.users.findIndex(function (user) {
    return user.name.toUpperCase() === userInfo.name.toUpperCase();
  });
  let user =
    userIndex < 0 ? { name: userInfo.name } : settings.users[userIndex];

  switch (userInfo.action) {
    case "avatar":
      user.avatar = userInfo.avatar;
      break;
    case "unmute":
      user.action = "none";
      break;
    default:
      user.action = userInfo.action;
      break;
  }

  if (user.action === "none" && !user.avatar) {
    if (userIndex >= 0) {
      settings.users.splice(userIndex, 1);
    }
  } else {
    if (userIndex < 0) {
      settings.users.push(user);
    } else {
      settings.users[userIndex] = user;
    }
  }

  localStorage.setItem("slogBlockerSettings", JSON.stringify(settings));
  return settings;
}
