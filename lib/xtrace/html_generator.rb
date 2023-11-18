# frozen_string_literal: true

require "stringio"

module XTrace
  class HTMLGenerator
    # Generates the HTML structure for the entire page
    def self.generate(trace_data)
      trace_id = JSON.parse(trace_data)["trace_id"]
      html = <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
          <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500&display=swap" rel="stylesheet">
          <title>XTrace</title>
          <style>
          body, html {
            font-family: 'Roboto', sans-serif;
            background-color: #f8f9fa;
            color: #333;
          }
          .container {
            display: flex;
            max-width: 960px;
            margin: 2em auto;
          }

          .main-content {
            flex: 1;
            background-color: #fff;
            border-radius: 16px;  /* Rounded corners */
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);  /* Deeper shadow for lift */
            padding: 24px;  /* Increased padding */
            margin: 16px;  /* Increased margin */
          }

          # .event-box {
          #   position: relative;
          #   background: linear-gradient(to right, #fff, #f1f1f1);
          #   border-radius: 12px;
          #   box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
          #   border-left: #007bff;
          #   margin: 10px 0;
          #   padding: 15px;
          #   transition: all 0.3s ease;  /* Smooth transitions */
          # }
          .event-box {
            position: relative;
            background: linear-gradient(to right, #fff, #f1f1f1);
            margin: 0.5em 0;
            padding: 0.75em;
            border-left: 4px solid #007bff; /* Use primary color for accent */
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
            transition: all 0.3s ease;  /* Smooth transitions */
          }
          .event-box:hover {
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);  /* Hover effect */
          }

          button {
            cursor: pointer;
            background-color: #007bff;
            color: #fff;
            border: none;
            padding: 0.5em 1em;
            border-radius: 4px;
            transition: background-color 0.3s;
          }
          button:hover {
            background-color: #0056b3; /* Darker shade on hover */
          }
          button.collapsible:hover {
            background-color: rgba(0, 128, 128, 0.1);  /* Button hover effect */
          }
          .event-box:before {
            content: "";
            position: absolute;
            top: 0;
            bottom: 0;
            left: 0;
            width: 4px;
            background-color: #ddd;
          }
          .event-box:first-child:before {
            top: 50%;
          }
          .event-box:last-child:before {
            bottom: 50%;
          }
          .event-box:empty {
            display: none;
          }
          .method-info {
            background-color: #e0f7fa;
            border-left: 4px solid #00bcd4;
            padding-left: 16px;
          }
          .method-info {
            color: #4CAF50;
            font-weight: bold;
          }
          .line-info, .return-info {
            color: #333;
          }
          .variables, .arguments, .scope, .file-info, .thread-info, .visibility-info {
            font-size: 0.9em;
            color: #666;
            margin-left: 20px;
          }
          .file-info, .visibility-info, .thread-info, .arguments {
            padding: 5px;
            border-left: 3px solid #ddd;
            margin: 5px 0;
            font-style: italic;
          }
          .line-info, .return-info {
            padding: 8px;
            background: rgba(0, 0, 0, 0.05);
            border-radius: 4px;
          }
          .collapsible {
            cursor: pointer;
            border: none;
            outline: none;
            text-align: left;
          }

          .content {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.2s ease-out;
          }

          /* Enhanced styles for better visual cues */
          .event-box.nested {
            border-left: 4px solid #00bcd4;
            margin-left: 20px;
          }
          .metadata {
            max-height: 300px;  /* or whatever maximum height you expect */
            overflow: hidden;
            transition: max-height 0.3s ease-out;
          }
          .meta-item {
            background-color: #f1f1f1;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8em;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);  /* Slight shadow */
          }
          .variables {
            display: inline-grid;
            grid-template-columns: repeat(2, auto);
            gap: 8px;
            background-color: #f5f5f5;
            border-radius: 8px;
            padding: 8px;
          }

          .variable {
            padding: 4px 8px;
            border-radius: 4px;
            background-color: #e5e5e5;
          }
          .line-num {
            background-color: #f1f1f1;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
            color: #333;
          }
          .line-content {
            flex: 1;
            margin-left: 8px;
            padding: 4px;
            background-color: #fafafa;
            border-radius: 4px;
            color: #555;
          }
          .variables {
            display: flex;
            flex-wrap: wrap;
            gap: 4px;
          }
          .variable {
            background-color: #e0f7fa;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8em;
          }
          .line-info {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 1.2em; /* Bigger and denser font */
          }
          .variable, .argument {
            font-size: 1.2em;
            font-weight: 600; /* Denser font */
            padding: 2px 6px;
            margin: 2px;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          }
          .premium-box {
            border: 2px solid #ddd;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            margin: 16px 0;
            padding: 16px;
          }
          ul.list,
          ul.list ul {
            margin:0;
            padding:0;
            list-style-type: none;
          }
          ul.list ul {
            position:relative;
            margin-left:10px;
          }
          ul.list ul:before {
            content:"";
            display:block;
            position:absolute;
            top:0;
            left:0;
            bottom:0;
            width:0;
            border-left:1px solid #ccc;
          }
          header, footer {
            padding: 16px;
            background: #f1f1f1;
            border-radius: 12px;
            margin-bottom: 16px;
          }

          header h1, header p, footer p {
            margin: 0;
            padding: 8px 0;
          }
          .line-info {
            display: flex;
            align-items: center;
            justify-content: flex-start;
            font-size: 1.2em;
            border-left: 4px solid #00bcd4; /* Highlight the line info */
            padding: 8px 16px;
            margin: 8px 0;
            background-color: #fafafa; /* Slight background */
            transition: all 0.3s ease;  /* Smooth transitions */
          }
          .line-info:hover {
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);  /* Hover effect */
            background-color: #f1f1f1;  /* Slight background change on hover */
          }

          /* Updated variable and argument styles */
          .arguments, .variables {
            display: flex;
            flex-wrap: wrap;
            gap: 4px;
            background-color: #f5f5f5;
            border-radius: 8px;
            padding: 8px;
          }
          .argument, .variable {
            background-color: #e0f7fa;
            font-size: 0.9em;  /* Smaller font */
            font-weight: 600;  /* Bold */
            font-style: normal;  /* No italic */
            color: #333;  /* Darker text */
            padding: 4px 8px;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);  /* More pronounced shadow */
            border: 1px solid #ccc;  /* Added border */
          }

          /* Updated return-related styles */
          .return-info {
            color: #4CAF50;  /* Green text for visibility */
            font-weight: bold;
            padding: 8px;
            background-color: rgba(255, 255, 255, 0.8);  /* Light background */
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);  /* More pronounced shadow */
            border: 1px solid #ccc;  /* Added border */
          }

          .line-info {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 1em;  /* Smaller, more code-like font */
            font-family: 'Courier New', Courier, monospace;  /* Code-like font */
            padding: 8px;
            background-color: rgba(255, 255, 255, 0.8);  /* Light background */
            border-radius: 4px;
            color: #333;  /* Darker text */
          }
          .line-num {
            background-color: #f1f1f1;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
            color: #333;
          }
          .line-content {
            flex: 1;
            margin-left: 8px;
            padding: 4px;
            background-color: #fafafa;
            border-radius: 4px;
            color: #555;
          }

          /* Updated meta-related styles */
          .metadata {
            display: flex;
            flex-wrap: wrap;
            gap: 4px;
            background-color: #f5f5f5;
            border-radius: 8px;
            padding: 8px;
          }
          .meta-item {
            background-color: #e0f7fa;
            font-size: 0.9em;  /* Smaller font */
            font-weight: 600;  /* Bold */
            color: #333;  /* Darker text */
            padding: 4px 8px;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);  /* More pronounced shadow */
            border: 1px solid #ccc;  /* Added border */
          }
          .arguments, .variables {
            display: flex;
            align-items: center;  /* Horizontal alignment */
          }
          .arguments:before, .variables:before {
            content: "Arguments: ";
            margin-right: 8px;
          }
          .variables:before {
            content: "Variables: ";
          }

          #toggle-variables-btn {
            cursor: pointer;
            background-color: #007bff;
            color: #fff;
            border: 2px solid #007bff;
            padding: 8px 16px;
            border-radius: 12px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          }

          #toggle-meta-btn {
            cursor: pointer;
            background-color: #007bff;
            color: #fff;
            border: 2px solid #007bff;
            padding: 8px 16px;
            border-radius: 12px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          }

          .shading-bar {
            height: 2px; /* height of the shading bar */
            background-color: red; /* color of the shading bar */
            position: absolute; /* positioning */
            top: 0; /* align to the top of the parent element */
            left: 0; /* align to the left of the parent element */
          }

          .sequence-number {
            font-weight: bold;
            color: #007bff; /* A shade of blue that matches buttons and links */
            background-color: #f0f0f0; /* Light grey background for contrast */
            padding: 4px 8px;
            border-radius: 4px; /* Rounded corners */
            margin-right: 8px; /* Space before the code block */
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1); /* Slight shadow for depth */
            display: inline-block;
            vertical-align: top; /* Aligns the sequence number with the top line of code */
          }
        </style>
        </head>
        <body>
          <div class="container">
            <div class="sidebar" id="sidebar">
              <!-- Sidebar Content: Dynamic Nav Links -->
            </div>
            <div class="main-content" id="main-content">
              <header>
                <h1>XTrace - Trace Data</h1>
                <p>Your insights into Ruby execution flow.</p>
                <p>Trace ID: #{trace_id}</p>
                <button id="toggle-variables-btn">Toggle All Variables</button>
                <button id="toggle-meta-btn">Toggle All Meta</button>
              </header>
              <div id="trace-data">
                <!-- Main Trace Data: This will be populated by JS -->
              </div>
              <footer>
                <p>Generated by XTrace</p>
              </footer>
            </div>
          </div>
          <script>
          // Function to get light background colors
          const elementColors = {};

          // Function to get light background colors
          function getLightColor(elementName) {
            const colors = ['#FAD02E', '#D4E09B', '#A3D39C', '#86E3CE', '#1ABC9C', '#ACD8AA', '#82E0AA', '#2ECC71', '#58D68D'];
            if (!elementColors[elementName]) {
              elementColors[elementName] = colors[Math.floor(Math.random() * colors.length)];
            }
            return elementColors[elementName];
          }

          // Collapsible functionality
          document.addEventListener("DOMContentLoaded", function() {
            let coll = document.getElementsByClassName("collapsible");
            for (let i = 0; i < coll.length; i++) {
              coll[i].addEventListener("click", function() {
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
                if (parent.classList.contains('content')) {
                  if (expanding) {
                    if (parent.style.maxHeight) {
                      parent.style.maxHeight = (parseInt(parent.style.maxHeight) + element.scrollHeight) + "px";
                    }
                  } else {
                    if (parent.style.maxHeight) {
                      parent.style.maxHeight = (parseInt(parent.style.maxHeight) - element.scrollHeight) + "px";
                    }
                  }
                }
                parent = parent.parentElement;
              }
            }
          });

          document.addEventListener("DOMContentLoaded", function() {
            const toggleMetaBtn = document.getElementById('toggle-meta-btn');
            let isMetaVisible = true;

            toggleMetaBtn.addEventListener('click', function() {
              isMetaVisible = !isMetaVisible;
              const metaDivs = document.querySelectorAll('.metadata');

              metaDivs.forEach((div) => {
                if (isMetaVisible) {
                  div.style.maxHeight = div.scrollHeight + "px";
                } else {
                  div.style.maxHeight = "0";
                }
              });
            });
          });

          document.addEventListener("DOMContentLoaded", function() {
            const toggleBtn = document.getElementById('toggle-variables-btn');
            let isVariablesVisible = true;

            toggleBtn.addEventListener('click', function() {
              isVariablesVisible = !isVariablesVisible;
              const variablesDivs = document.querySelectorAll('.variables');

              variablesDivs.forEach((div) => {
                div.style.display = isVariablesVisible ? 'block' : 'none';
              });
            });
          });

          function getMaxTime(events) {
            let maxTime = 0;
            events.forEach(event => {
              if (event.type === 'line' && event.time_taken > maxTime) {
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
            if (obj === null || typeof obj !== 'object') {
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

          function displayExecutionFlow(events, level = 0, sequence = '') {
            const maxTime = getMaxTime(events);
            let output = '';
            const indent = ' '.repeat(level * 2);
            let eventCounter = 1; // Initialize event counter

            if (level > 0) {
              output += `<button class='collapsible'>Nested Calls</button>`;
              output += `<div class='content'>`;
            }

            events.forEach((event) => {
              if (event) {
                let eventContent = '';
                const currentSequence = sequence ? `${sequence}.${eventCounter}` : `${eventCounter}`;

                if (event.type === 'call' && event.call) {
                  eventContent += `<div class='method-info'>${indent}${currentSequence} - Method: ${event.call.method_name}</div>`;
                  eventContent += `<div class='metadata'>`;
                  ['file', 'visibility', 'class_or_module', 'thread_id', 'instance_id'].forEach(key => {
                    eventContent += `<span class='meta-item'>${key.replace('_', ' ').toUpperCase()}: ${event.call[key]}</span>`;
                  });
                  eventContent += `</div>`;
                  eventContent += `<div class='arguments'>`;
                  Object.keys(event.call.arguments).forEach(key => {
                    const color = getLightColor(key);
                    const value = serializeObject(event.call.arguments[key]);
                    eventContent += `<span class='argument' style='background-color: ${color};'>${key}: ${value}</span> `;
                  });
                  eventContent += `</div>`;

                  if (event.call.events && event.call.events.length > 0) {
                    eventContent += displayExecutionFlow(event.call.events, level + 1, currentSequence);
                  }
                } else if (event.type === 'line') {
                  const barWidth = getBarWidth(event.time_taken, maxTime);
                  eventContent += `<div class='line-info' style='position: relative;'>${indent}${currentSequence} - [Line:${event.line}] ${event.statement_content}`;
                  eventContent += `<div class='shading-bar' style='width: ${barWidth}%; background-color: ${getShade(event.time_taken, maxTime)};'></div></div>`;
                  eventContent += `<div class='metadata'>`;
                  eventContent += `<span class='meta-item'>Time Taken: ${(event.time_taken * 1000).toLocaleString(undefined, { maximumFractionDigits: 2 })} ms</span>`;
                  eventContent += `<span class='meta-item'>Heap Size Diff: ${event.heap_size_diff.toLocaleString()} bytes</span>`;
                  eventContent += `<span class='meta-item'>Heap Live Slots: ${event.gc_metric.toLocaleString()}</span>`;
                  eventContent += `</div>`;
                  eventContent += `<div class='variables'>`;
                  Object.keys(event.variables).forEach(key => {
                    const color = getLightColor(key);
                    const value = serializeObject(event.variables[key]);
                    eventContent += `<span class='variable' style='background-color: ${color};'>${key}: ${value}</span> `;
                  });
                  eventContent += `</div>`;
                } else if (event.type === 'return') {
                  const returnValue = serializeObject(event.return_value);
                  eventContent += `<div class='return-info'>${indent}${currentSequence} - Returned: ${returnValue}</div>`;
                }

                if (eventContent.trim().length > 0) {
                  output += `<div class='event-box' style='margin-left:${level * 20}px;'>${eventContent}</div>`;
                  eventCounter++; // Increment event counter only when we add content
                }
              }
            });

            if (level > 0) {
              output += `</div>`; // Close content div for collapsible
            }

            return output;
          }
          const traceData = #{trace_data};
          const traceDataDiv = document.getElementById("trace-data");  // Target the new div
          const mainContent = document.getElementById("main-content");

          if (traceData.child_calls && traceData.child_calls.length > 0) {
            traceDataDiv.innerHTML = displayExecutionFlow(traceData.child_calls[0].events);
          } else if (traceData.events && traceData.events.length > 0) {
            traceDataDiv.innerHTML = displayExecutionFlow(traceData.events);
          } else {
            traceDataDiv.innerHTML = "No data to display.";
          }
          </script>
        </div>
      </div>
        </body>
        </html>
      HTML
      html
    end
  end
end
