/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

var app = {
    // Application Constructor
    initialize: function() {
        document.addEventListener('deviceready', this.onDeviceReady.bind(this), false);

        var heightOutput = document.querySelector('#height');
        var widthOutput = document.querySelector('#width');

        function resize() { 
            heightOutput.textContent = window.innerHeight;
            widthOutput.textContent = window.innerWidth;
        }

        window.onresize = resize;
        resize();
    },

    // deviceready Event Handler
    //
    // Bind any cordova events here. Common events are:
    // 'pause', 'resume', etc.
    onDeviceReady: function() {
        var shrinkView = document.getElementById('shrink-view');
        var hideBar = document.getElementById('show-bar');
        var disableScroll = document.getElementById('disable-scroll');

        var isShrinkView = false,
            isHideBar = false,
            isDisableScroll = false;

        shrinkView.onclick = function () {
            Keyboard.shrinkView(!isShrinkView);
            isShrinkView = !isShrinkView;
            shrinkView.textContent = "Shrink View: " + (isShrinkView ? "True" : "False");
        };

        hideBar.onclick = function () {
            Keyboard.hideFormAccessoryBar(!isHideBar);
            isHideBar = !isHideBar;
            hideBar.textContent = "Hide Bar: " + (isHideBar ? "True" : "False");
        };

        disableScroll.onclick = function () {
            Keyboard.disableScrollingInShrinkView(!isDisableScroll);
            isDisableScroll = !isDisableScroll;
            disableScroll.textContent = "Disable Scroll: " + (isDisableScroll ? "True" : "False");
        };
    }
};

app.initialize();
