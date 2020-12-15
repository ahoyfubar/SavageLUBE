function createOptionForAction(label, value, action) {
  let option = document.createElement("option");
  option.textContent = label;
  option.value = value;
  if (value === action) {
    option.selected = "selected";
  }
  return option;
}

function createSelectForAction(action) {
  let select = document.createElement("select");
  select.appendChild(createOptionForAction("Blocked", "hide", action));
  select.appendChild(createOptionForAction("Muted", "mute", action));
  select.appendChild(createOptionForAction("Visible", "none", action));
  return select;
}

function insertRowForUser(table, user) {
  let row = table.insertRow();
  let cell = row.insertCell();
  cell.appendChild(document.createTextNode(user.name));
  cell = row.insertCell();
  cell.appendChild(createSelectForAction(user.action));
}

function applySettings(settingsString) {
  let settings = JSON.parse(settingsString);
  let options = document
    .getElementById("options")
    .getElementsByTagName("input");
  for (i = 0; i < options.length; i++) {
    options[i].checked = settings[options[i].id];
  }

  let userElement = document.getElementById("users");
  let userTable = userElement.getElementsByTagName("table")[0];
  while(userTable.rows.length > 0) {
    userTable.deleteRow(0);
  }
  for (i = 0; i < settings.users.length; i++) {
    let user = settings.users[i];
    if (user.action !== "none") {
      insertRowForUser(userTable, user);
    }
  }
  userElement.hidden = userTable.rows.length < 1;
  return true;
}

function applyActionToUser(row, users) {
  let name = row.cells[0].textContent;
  let userIndex = users.findIndex(function (user) {
    return user.name.toUpperCase() === name.toUpperCase();
  });
  let action = row.getElementsByTagName("select")[0].value;
  if (action === "none" && !users[userIndex].avatar) {
    users.splice(userIndex, 1);
  } else {
    users[userIndex].action = action;
  }
}

function retrieveSettings(settingsString) {
  let settings = JSON.parse(settingsString);
  let options = document
    .getElementById("options")
    .getElementsByTagName("input");
  for (i = 0; i < options.length; i++) {
    settings[options[i].id] = options[i].checked;
  }

  let users = document.getElementById("users").getElementsByTagName("tr");
  for (i = 0; i < users.length; i++) {
    applyActionToUser(users[i], settings.users);
  }

  return JSON.stringify(settings);
}

function loadSettingsChrome() {
  if (applySettings(localStorage.getItem("slogBlockerSettings"))) {
    var saveButton = document.getElementById("save");
    saveButton.hidden = false;
    saveButton.addEventListener("click", saveSettingsChrome);
  }
}

function saveSettingsChrome() {
  var settings = retrieveSettings(localStorage.getItem("slogBlockerSettings"));
  localStorage.setItem("slogBlockerSettings", settings);

  chrome.runtime.sendMessage({
    message: "slogBlockerSettingsChanged",
  });

  var status = document.getElementById("status");
  status.textContent = "Preferences saved";
  setTimeout(function () {
    status.textContent = "";
    location.reload();
  }, 1000);
}

document.addEventListener("DOMContentLoaded", function() {
  if (typeof safari === 'undefined') {
    loadSettingsChrome();
  }
});
