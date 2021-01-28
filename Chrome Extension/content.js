// content.js

if (typeof safari !== "undefined") {
  console.log("SlogBlocker on Safari");
  document.addEventListener("DOMContentLoaded", function (event) {
    if (document.body.classList.contains("article-section-savage-love")) {
      // Set us up to receive messages from the app
      safari.self.addEventListener("message", handleMessageSafari);
      // Let the application know the page was reloaded
      safari.extension.dispatchMessage("DOMContentLoaded");
    }
  });
} else {
  console.log("SlogBlocker on Chromium");
  if (document.body.classList.contains("article-section-savage-love")) {
    // Set us up to receive messages from the app
    chrome.runtime.onMessage.addListener(handleMessageChromium);
    // Let the extension know we're here
    chrome.runtime.sendMessage({
      message: "DOMContentLoaded",
    });
  }
}

function handleMessageSafari(event) {
  // Filter comments in the DOM
  if (event.name === "filterComments") {
    filterComments(event.message);
  }
  // Refresh after user blocked/muted
  else if (event.name === "settingsUpdated") {
    location.reload();
  }
}

function handleMessageChromium(request, sender, sendResponse) {
  // Filter comments in the DOM
  if (request.message === "filterComments") {
    filterComments(request.appInfo);
  }
  // Refresh after user blocked/muted
  else if (request.message === "settingsUpdated") {
    location.reload();
  }
  return true;
}

function filterComments(appInfo) {
  if (document.body.classList.contains("article-section-savage-love")) {
    const path = "/savage-love/comments";
    const href = window.location.href;
    const pathlen = href.indexOf(path) + path.length;
    const baseurl = href.substring(0, pathlen) + "/";
    const tagno = parseInt(href.substring(pathlen + 1) || 0);

    const comments = document.body.getElementsByClassName("comment-container");
    for (let i = 0; i < comments.length; i++) {
      const byline = comments[i].getElementsByClassName("comment-byline");
      const name = byline[0].firstChild.nextSibling.firstChild.text;
      const menu = addBlockerMenu(name);
      byline[0].parentNode.appendChild(menu);

      addAvatarSelector(comments[i], name);

      if (Array.isArray(appInfo.users)) {
        const user = appInfo.users.find(
          (u) => u.name.toLowerCase() === name.toLowerCase()
        );
        if (typeof user !== "undefined") {
          if (user.action == "hide") {
            hideComment(comments[i]);
          } else if (user.action === "mute") {
            muteComment(comments[i], user.text, menu);
            updateBlockerMenuMuted(comments[i], menu);
          } else if (user.action === "bold") {
            boldComment(comments[i]);
            updateBlockerMenuBolded(comments[i], menu);
          }
          if (user.avatar !== undefined) {
            replaceAvatar(comments[i], user.avatar);
          }
        }
      }

      if (appInfo.addCommentLinks == true) {
        addCommentLinks(baseurl, comments[i]);
      }
      if (appInfo.addAvatarTooltips == true) {
        addAvatarTooltip(comments[i], name);
      }
      if (appInfo.moveUserBylines == true) {
        moveUserByline(comments[i]);
      }
    }
    if (comments.length > 0 && appInfo.addTopPagination == true) {
      addTopPagination(comments);
    }
    if (tagno) {
      adjustScrollToComment(tagno);
    }
  }
}

function addAvatarSelector(comment, name) {
  const image = comment.getElementsByClassName("user-image");
  image[0].onclick = function () {
    const avatar = image[0].getElementsByTagName("img");
    let imgsrc = "";
    if (avatar.length > 0) {
      imgsrc = avatar[0].src;
    }
    const result = window.prompt("Enter Avatar URL", imgsrc);
    if (result !== null) {
      function notifyChangeAvatar(avatar) {
        if (typeof safari !== "undefined") {
          safari.extension.dispatchMessage("changeAvatar", {
            name: name,
            action: "avatar",
            avatar: avatar,
          });
        } else {
          chrome.runtime.sendMessage({
            message: "changeAvatar",
            userInfo: {
              name: name,
              action: "avatar",
              avatar: avatar,
            },
          });
        }
      }
      if (result.length > 0) {
        const img = new Image();
        img.onload = function () {
          notifyChangeAvatar(result);
          image[0].innerHTML = '<img src="' + result + '" style="width:100%;">';
        };
        img.onerror = function () {
          alert("Image not found at " + result);
        };
        img.src = result;
      } else {
        notifyChangeAvatar("");
      }
    }
  };
}

function addBlockerMenuBoldButton(menu, name) {
  const button = document.createElement("button");
  button.classList.add("bold-user");
  button.appendChild(document.createTextNode("Highlight user"));

  button.onclick = function () {
    if (button.classList.contains("unbold-user")) {
      if (typeof safari !== "undefined") {
        safari.extension.dispatchMessage("blockUser", {
          name: name,
          action: "unbold",
        });
      } else {
        chrome.runtime.sendMessage({
          message: "blockUser",
          userInfo: {
            name: name,
            action: "unbold",
          },
        });
      }
    } else {
      if (typeof safari !== "undefined") {
        safari.extension.dispatchMessage("blockUser", {
          name: name,
          action: "bold",
        });
      } else {
        chrome.runtime.sendMessage({
          message: "blockUser",
          userInfo: {
            name: name,
            action: "bold",
          },
        });
      }
    }
  };
  return button;
}

function addBlockerMenuBlockButton(name) {
  const button = document.createElement("button");
  button.classList.add("block-user");
  button.appendChild(document.createTextNode("Block user"));

  button.onclick = function () {
    if (confirm("Are you sure you want to block " + name + "?")) {
      if (typeof safari !== "undefined") {
        safari.extension.dispatchMessage("blockUser", {
          name: name,
          action: "hide",
        });
      } else {
        chrome.runtime.sendMessage({
          message: "blockUser",
          userInfo: {
            name: name,
            action: "hide",
          },
        });
      }
    }
  };
  return button;
}

function addBlockerMenuMuteButton(name) {
  const button = document.createElement("button");
  button.classList.add("mute-user");
  button.appendChild(document.createTextNode("Mute user"));

  button.onclick = function () {
    if (button.classList.contains("unmute-user")) {
      if (typeof safari !== "undefined") {
        safari.extension.dispatchMessage("blockUser", {
          name: name,
          action: "unmute",
        });
      } else {
        chrome.runtime.sendMessage({
          message: "blockUser",
          userInfo: {
            name: name,
            action: "unmute",
          },
        });
      }
    } else if (confirm("Are you sure you want to mute " + name + "?")) {
      if (typeof safari !== "undefined") {
        safari.extension.dispatchMessage("blockUser", {
          name: name,
          action: "mute",
        });
      } else {
        chrome.runtime.sendMessage({
          message: "blockUser",
          userInfo: {
            name: name,
            action: "mute",
          },
        });
      }
    }
  };
  return button;
}

function addBlockerMenu(name) {
  const menu = document.createElement("span");
  menu.classList.add("weak");
  menu.classList.add("blocker-menu");

  if (name.split("").reverse().join("") !== "rabuf") {
    const blockButton = addBlockerMenuBlockButton(name);
    menu.appendChild(document.createTextNode(" · "));
    menu.appendChild(blockButton);

    const muteButton = addBlockerMenuMuteButton(name);
    menu.appendChild(document.createTextNode(" · "));
    menu.appendChild(muteButton);
  }

  const boldButton = addBlockerMenuBoldButton(menu, name);
  menu.appendChild(document.createTextNode(" · "));
  menu.appendChild(boldButton);

  return menu;
}

function updateBlockerMenuBolded(comment, menu) {
  const bold = menu.getElementsByClassName("bold-user");
  changeButtonText(bold[0], "Unhighlight user");
  bold[0].classList.add("unbold-user");
  bold[0].classList.remove("bold-user");
}

function updateBlockerMenuMuted(comment, menu) {
  const mute = menu.getElementsByClassName("mute-user");
  changeButtonText(mute[0], "Unmute user");
  mute[0].classList.add("unmute-user");
  mute[0].classList.remove("mute-user");

  const bold = menu.getElementsByClassName("bold-user");
  bold[0].parentNode.removeChild(bold[0].previousSibling);
  bold[0].parentNode.removeChild(bold[0]);

  const button = document.createElement("button");
  button.classList.add("show-comment");
  button.appendChild(document.createTextNode("Show comment"));
  menu.appendChild(document.createTextNode(" · "));
  menu.appendChild(button);

  button.onclick = function () {
    const body = comment.getElementsByClassName("comment-body");
    const mute = body[0].firstChild.nextSibling;
    if (mute.classList.contains("comment-muted")) {
      mute.classList.remove("comment-muted");
      mute.nextSibling.classList.add("comment-muted");
      changeButtonText(button, "Show comment");
    } else {
      mute.classList.add("comment-muted");
      mute.nextSibling.classList.remove("comment-muted");
      changeButtonText(button, "Hide comment");
    }
  };
}

function changeButtonText(button, text) {
  button.removeChild(button.firstChild);
  button.appendChild(document.createTextNode(text));
}

function boldComment(comment) {
  comment.classList.add("selected");
}

function hideComment(comment) {
  comment.style.display = "none";
}

function muteComment(comment, mask, menu) {
  const body = comment.getElementsByClassName("comment-body");
  const mute = document.createElement("div");
  mute.classList.add("comment-muted");

  let text = body[0].firstChild.nextSibling.nextSibling;
  while (text) {
    const next = text.nextSibling;
    body[0].removeChild(text);
    mute.appendChild(text);
    text = next;
  }

  const para = document.createElement("p");
  if (typeof mask === "undefined") {
    mask = "...";
  }
  para.appendChild(document.createTextNode(mask));

  const toggle = document.createElement("div");
  toggle.classList.add("comment-placeholder");
  toggle.appendChild(para);

  body[0].appendChild(toggle);
  body[0].appendChild(mute);
}

function replaceAvatar(comment, avatar) {
  const image = comment.getElementsByClassName("user-image");
  image[0].innerHTML = '<img src="' + avatar + '" style="width:100%;">';
}

function addAvatarTooltip(comment, name) {
  const image = comment.getElementsByClassName("user-image");
  image[0].classList.add("user-tooltip");

  const tooltip = document.createElement("span");
  tooltip.classList.add("user-tooltip-text");
  tooltip.appendChild(document.createTextNode(name));
  image[0].insertBefore(tooltip, image[0].firstChild);
}

function addCommentLinks(baseurl, comment) {
  const body = comment.getElementsByClassName("comment-body");
  const tags = body[0].getElementsByTagName("p");
  for (i = 0; i < tags.length; i++) {
    const outerHTML = tags[i].outerHTML;
    const parts = outerHTML.split("@");
    if (parts.length > 1) {
      for (j = 1; j < parts.length; j++) {
        let found = false;
        const refno = parts[j].match(/^ ?[0-9]+/g);
        if (refno) {
          const tagno = parseInt(refno[0]);
          if (tagno > 0) {
            const target = document.getElementById("comment-" + tagno);
            const href = target ? "#comment-" : baseurl;
            const link = "<a href='" + href + tagno + "'>@" + refno + "</a>";
            const text = parts[j].substring(refno[0].length);
            parts[j] = link + text;
            found = true;
          }
        }
        if (!found) {
          parts[j] = `@${parts[j]}`;
        }
      }
      tags[i].outerHTML = parts.join("");
    }
  }
}

function addTopPagination(comments) {
  const pager = document.getElementById("commentPagination");
  if (pager) {
    const clone = pager.parentNode.cloneNode(true);
    clone.firstChild.id = "commentPaginationTop";
    const wrapper = document.createElement("div");
    wrapper.classList.add("row");
    wrapper.appendChild(clone);
    comments[0].parentNode.insertBefore(wrapper, comments[0]);
  }
}

function moveUserByline(comment) {
  const header = comment.getElementsByClassName("comment-header");
  const footer = comment.getElementsByClassName("comment-footer");

  let node = footer[0].firstChild;
  while (node) {
    footer[0].removeChild(node);
    header[0].appendChild(node);
    node = footer[0].firstChild;
  }

  const number = comment.getElementsByClassName("comment-number");
  const link = number[0];
  link.parentNode.removeChild(link);
  header[0].appendChild(link);
  header[0].classList.add("text-muted");
  header[0].classList.add("byline-header");
}

function isElementInViewport(el) {
  const rect = el.getBoundingClientRect();
  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <=
      (window.innerHeight || document.documentElement.clientHeight) &&
    rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  );
}

function scrollToComment(tagno) {
  const target = document.getElementById("comment-" + tagno);
  if (target && !isElementInViewport(target)) {
    if (typeof chrome !== "undefined") {
      const y = target.getBoundingClientRect().top + window.scrollY;
      window.scroll({
        top: y,
        behavior: "smooth",
      });
    } else {
      target.scrollIntoView();
    }
  }
}

function adjustScrollToComment(tagno) {
  let scrollTimer = -1;
  const scrollListener = function () {
    if (scrollTimer !== -1) {
      clearTimeout(scrollTimer);
    }
    scrollTimer = setTimeout(function () {
      clearTimeout(scrollTimer);
      window.removeEventListener("scroll", scrollListener);
      scrollToComment(tagno);
    }, 500);
  };
  window.addEventListener("scroll", scrollListener, false);
}
