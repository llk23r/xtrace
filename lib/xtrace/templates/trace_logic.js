// Function to get light background colors
const elementColors = {};

// Function to get light background colors
function getLightColor(elementName) {
  const colors = [
    "#FAD02E",
    "#D4E09B",
    "#A3D39C",
    "#86E3CE",
    "#1ABC9C",
    "#ACD8AA",
    "#82E0AA",
    "#2ECC71",
    "#58D68D",
  ];
  if (!elementColors[elementName]) {
    elementColors[elementName] =
      colors[Math.floor(Math.random() * colors.length)];
  }
  return elementColors[elementName];
}

// Collapsible functionality
document.addEventListener("DOMContentLoaded", function () {
  let coll = document.getElementsByClassName("collapsible");
  for (let i = 0; i < coll.length; i++) {
    coll[i].addEventListener("click", function () {
      this.classList.toggle("active");
      let content = this.nextElementSibling;
      if (content.style.maxHeight) {
        content.style.maxHeight = null;
        updateParentHeights(content, false);
      } else {
        content.style.maxHeight = content.scrollHeight + "px";
        updateParentHeights(content, true);
      }
    });
  }

  // Recursive function to update max-height of parent collapsibles
  function updateParentHeights(element, expanding) {
    let parent = element.parentElement;
    // Loop through all parent nodes
    while (parent) {
      if (parent.classList.contains("content")) {
        if (expanding) {
          if (parent.style.maxHeight) {
            parent.style.maxHeight =
              parseInt(parent.style.maxHeight) + element.scrollHeight + "px";
          }
        } else {
          if (parent.style.maxHeight) {
            parent.style.maxHeight =
              parseInt(parent.style.maxHeight) - element.scrollHeight + "px";
          }
        }
      }
      parent = parent.parentElement;
    }
  }
});

document.addEventListener("DOMContentLoaded", function () {
  const toggleMetaBtn = document.getElementById("toggle-meta-btn");
  let isMetaVisible = true;

  toggleMetaBtn.addEventListener("click", function () {
    isMetaVisible = !isMetaVisible;
    const metaDivs = document.querySelectorAll(".metadata");

    metaDivs.forEach((div) => {
      if (isMetaVisible) {
        div.style.maxHeight = div.scrollHeight + "px";
      } else {
        div.style.maxHeight = "0";
      }
    });
  });
});

document.addEventListener("DOMContentLoaded", function () {
  const toggleBtn = document.getElementById("toggle-variables-btn");
  let isVariablesVisible = true;

  toggleBtn.addEventListener("click", function () {
    isVariablesVisible = !isVariablesVisible;
    const variablesDivs = document.querySelectorAll(".variables");

    variablesDivs.forEach((div) => {
      div.style.display = isVariablesVisible ? "block" : "none";
    });
  });
});

function getMaxTime(events) {
  let maxTime = 0;
  events.forEach((event) => {
    if (event.type === "line" && event.time_taken > maxTime) {
      maxTime = event.time_taken;
    }
  });
  return maxTime;
}

function getBarWidth(time_taken, maxTime) {
  return (time_taken / maxTime) * 100; // returns a percentage
}

function getShade(time_taken, maxTime) {
  const percentage = (time_taken / maxTime) * 100;
  return `rgba(255, 0, 0, ${percentage / 100})`; // Using red as the shading color
}

// Helper function to serialize an object for display
function serializeObject(obj) {
  if (obj === null || typeof obj !== "object") {
    // Return the value as is if it's not an object
    return obj;
  } else if (Array.isArray(obj)) {
    // Serialize array elements
    return obj.map(serializeObject);
  } else {
    // Create a new object to hold the serialized properties
    const serialized = {};
    for (const [key, value] of Object.entries(obj)) {
      // Serialize each property
      serialized[key] = serializeObject(value);
    }
    // Convert the object to a JSON string for display
    return JSON.stringify(serialized, null, 2);
  }
}

function displayExecutionFlow(events, level = 0, sequence = "") {
  const maxTime = getMaxTime(events);
  let output = "";
  const indent = " ".repeat(level * 2);
  let eventCounter = 1; // Initialize event counter

  if (level > 0) {
    output += `<button class='collapsible'>Nested Calls</button>`;
    output += `<div class='content'>`;
  }

  events.forEach((event) => {
    if (event) {
      let eventContent = "";
      const currentSequence = sequence
        ? `${sequence}.${eventCounter}`
        : `${eventCounter}`;

      if (event.type === "call" && event.call) {
        eventContent += `<div class='method-info'>${indent}${currentSequence} - Method: ${event.call.method_name}</div>`;
        eventContent += `<div class='metadata'>`;
        [
          "file",
          "visibility",
          "class_or_module",
          "thread_id",
          "instance_id",
        ].forEach((key) => {
          eventContent += `<span class='meta-item'>${key
            .replace("_", " ")
            .toUpperCase()}: ${event.call[key]}</span>`;
        });
        eventContent += `</div>`;
        eventContent += `<div class='arguments'>`;
        Object.keys(event.call.arguments).forEach((key) => {
          const color = getLightColor(key);
          const value = serializeObject(event.call.arguments[key]);
          eventContent += `<span class='argument' style='background-color: ${color};'>${key}: ${value}</span> `;
        });
        eventContent += `</div>`;

        if (event.call.events && event.call.events.length > 0) {
          eventContent += displayExecutionFlow(
            event.call.events,
            level + 1,
            currentSequence
          );
        }
      } else if (event.type === "line") {
        const barWidth = getBarWidth(event.time_taken, maxTime);
        eventContent += `<div class='line-info' style='position: relative;'>${indent}${currentSequence} - [Line:${event.line}] ${event.statement_content}`;
        eventContent += `<div class='shading-bar' style='width: ${barWidth}%; background-color: ${getShade(
          event.time_taken,
          maxTime
        )};'></div></div>`;
        eventContent += `<div class='metadata'>`;
        eventContent += `<span class='meta-item'>Time Taken: ${(
          event.time_taken * 1000
        ).toLocaleString(undefined, { maximumFractionDigits: 2 })} ms</span>`;
        eventContent += `<span class='meta-item'>Heap Size Diff: ${event.heap_size_diff.toLocaleString()} bytes</span>`;
        eventContent += `<span class='meta-item'>Heap Live Slots: ${event.gc_metric.toLocaleString()}</span>`;
        eventContent += `</div>`;
        eventContent += `<div class='variables'>`;
        Object.keys(event.variables).forEach((key) => {
          const color = getLightColor(key);
          const value = serializeObject(event.variables[key]);
          eventContent += `<span class='variable' style='background-color: ${color};'>${key}: ${value}</span> `;
        });
        eventContent += `</div>`;
      } else if (event.type === "return") {
        const returnValue = serializeObject(event.return_value);
        eventContent += `<div class='return-info'>${indent}${currentSequence} - Returned: ${returnValue}</div>`;
      }

      if (eventContent.trim().length > 0) {
        output += `<div class='event-box' style='margin-left:${
          level * 20
        }px;'>${eventContent}</div>`;
        eventCounter++; // Increment event counter only when we add content
      }
    }
  });

  if (level > 0) {
    output += `</div>`; // Close content div for collapsible
  }

  return output;
}
const traceDataDiv = document.getElementById("trace-data"); // Target the new div
const mainContent = document.getElementById("main-content");

if (traceData.child_calls && traceData.child_calls.length > 0) {
  traceDataDiv.innerHTML = displayExecutionFlow(
    traceData.child_calls[0].events
  );
} else if (traceData.events && traceData.events.length > 0) {
  traceDataDiv.innerHTML = displayExecutionFlow(traceData.events);
} else {
  traceDataDiv.innerHTML = "No data to display.";
}
