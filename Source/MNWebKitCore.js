//  MNWebKitCore.js
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

// Helper methods

function assign(obj, keyPath, value) {
    var lastKeyIndex = keyPath.length - 1;
    for (var i = 0; i < lastKeyIndex; ++ i) {
        key = keyPath[i];
        if (!(key in obj)) {
            obj[key] = {};
        }
        obj = obj[key];
    }
    obj[keyPath[lastKeyIndex]] = value;
}

// Objc facing

function createScriptMessageHandler(name) {
    var methods = {
        'postMessage': function(messageBody) { this.messageBody = messageBody; sendMsgToObjC('scriptMessageReady' + ':' + name); }
    };
    
    assign(window, ['webkit', 'messageHandlers', name, 'postMessage'], methods['postMessage']);
}

function getMessageBodyForScriptMessageHandler(name) {
    var messageBody = window.webkit.messageHandlers[name].messageBody;
    window.webkit.messageHandlers[name].messageBody = null;
    
    return messageBody;
}

function removeScriptMessageHandler(name) {
    window.webkit.messageHandlers[name] = null;
}

function sendMsgToObjC(str) {
    var iframe = document.createElement('IFRAME');
    iframe.setAttribute('src', 'mncallback' + ':' + encodeURIComponent(str));
    document.documentElement.appendChild(iframe);
    iframe.parentNode.removeChild(iframe);
    iframe = null;
}

function nsLog(str) {
    sendMsgToObjC('nsLog' + ':' + str);
}