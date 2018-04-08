// This file contains the source for the Javascript side of the
// WebViewJavascriptBridge. It is plaintext, but converted to an NSString
// via some preprocessor tricks.
//
// Previous implementations of WebViewJavascriptBridge loaded the javascript source
// from a resource. This worked fine for app developers, but library developers who
// included the bridge into their library, awkwardly had to ask consumers of their
// library to include the resource, violating their encapsulation. By including the
// Javascript as a string resource, the encapsulation of the library is maintained.

#import "WebViewJavascriptBridge_JS.h"

NSString * WebViewJavascriptBridge_js() {
	#define __wvjb_js_func__(x) #x
	
	// BEGIN preprocessorJSCode
	static NSString * preprocessorJSCode = @__wvjb_js_func__(
;(function() {
    // funtion(){}(); 自执行函数
	if (window.WebViewJavascriptBridge) {
		return;
	}
    
	if (!window.onerror) {
		window.onerror = function(msg, url, line) {
			console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
		}
	}
	window.WebViewJavascriptBridge = {
		registerHandler: registerHandler,
		callHandler: callHandler,
		disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
		_fetchQueue: _fetchQueue,
		_handleMessageFromObjC: _handleMessageFromObjC
	};
    // 这些都是 window 的属性吧
	var messagingIframe;
    // 用于存储消息列表
	var sendMessageQueue = [];
        // 用于存储消息{key:value}
	var messageHandlers = {};
	// 下面两个是特定的组合
	var CUSTOM_PROTOCOL_SCHEME = 'https';
	var QUEUE_HAS_MESSAGE = '__wvjb_queue_message__';
	// oc 调用 js 的回调
    // oc 注册方法的时候，js 调用后，走到 oc 中，然后 oc 处理，如果 oc 需要将处理的结果回传给 js，那么会有 responseCallback
	var responseCallbacks = {};
    // 消息对应的 id
	var uniqueId = 1;
    // 是否设置消息超时
	var dispatchMessagesWithTimeoutSafety = true;
    // 保存 JS 注册的方法
	function registerHandler(handlerName, handler) {
		messageHandlers[handlerName] = handler;
	}
	// js 调用 OC 注册的方法
	function callHandler(handlerName, data, responseCallback) {
        // 参数矫正
		if (arguments.length == 2 && typeof data == 'function') {
			responseCallback = data;
			data = null;
		}
		_doSend({ handlerName:handlerName, data:data }, responseCallback);
	}
	function disableJavscriptAlertBoxSafetyTimeout() {
		dispatchMessagesWithTimeoutSafety = false;
	}
	// 发送 js 调用 OC 方法的消息
	function _doSend(message, responseCallback) {
        // 如果 oc 处理完后，需要回调给 js，那么需要一个 id ，保存中回调的方法
        // 如果是 js 处理完后，回调给 oc 那么就没有 responseCallback
		if (responseCallback) {
            // 保存回调
			var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
			responseCallbacks[callbackId] = responseCallback;
			message['callbackId'] = callbackId;
		}
        // 保存到数组中
		sendMessageQueue.push(message);
        // 触发 WKWebView 的代理
		messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
	}

    // 将当前 sendMessageQueue 数组中存储的消息，转为 JSON 字符串返回。
	function _fetchQueue() {
        // JSON.stringify 对象转 JSON 字符串
		var messageQueueString = JSON.stringify(sendMessageQueue);
        // 清空上次保存的消息数组
		sendMessageQueue = [];
		return messageQueueString;
	}
    
    // 处理从 OC 过来的消息
	function _dispatchMessageFromObjC(messageJSON) {
		if (dispatchMessagesWithTimeoutSafety) {
			setTimeout(_doDispatchMessageFromObjC);
		} else {
			 _doDispatchMessageFromObjC();
		}
		
		function _doDispatchMessageFromObjC() {
            // JSON 字符串转为 JSON 对象
			var message = JSON.parse(messageJSON);
			var messageHandler;
			var responseCallback;

			if (message.responseId) {
                // js 调用 OC 方法后，OC 处理获取结果后，回传给 JS
				responseCallback = responseCallbacks[message.responseId];
				if (!responseCallback) {
					return;
				}
				responseCallback(message.responseData);
				// 删除上次保存
				delete responseCallbacks[message.responseId];
			} else {
                // OC 主动调用 JS 方法
				if (message.callbackId) {
					var callbackResponseId = message.callbackId;
                    // js 回传 OC
					responseCallback = function(responseData) {
						// 这个是为了触发oc的回到
						_doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
					};
				}
				// 获取 JS 注册的方法
				var handler = messageHandlers[message.handlerName];
				if (!handler) {
					console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
				} else {
                    // 调用 JS 中对应的函数
					handler(message.data, responseCallback);
				}
			}
		}
	}
	
    // OC 调用 JS方法的入口
	function _handleMessageFromObjC(messageJSON) {
        _dispatchMessageFromObjC(messageJSON);
	}

	messagingIframe = document.createElement('iframe');
	messagingIframe.style.display = 'none';
	messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
	document.documentElement.appendChild(messagingIframe);

	registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
    // 初始化WEB中注册的方法。这个方法会把WEB中的hander注册到bridge中。
    // 下面的代码其实就是执行WEB中的callback函数。
	setTimeout(_callWVJBCallbacks, 0);
	function _callWVJBCallbacks() {
		var callbacks = window.WVJBCallbacks;
		delete window.WVJBCallbacks;
		for (var i=0; i<callbacks.length; i++) {
			callbacks[i](WebViewJavascriptBridge);
		}
	}
})();
	); // END preprocessorJSCode

	#undef __wvjb_js_func__
	return preprocessorJSCode;
};
