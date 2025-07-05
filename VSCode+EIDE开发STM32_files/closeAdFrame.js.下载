/*
 *广告关闭
 */
 (function(){
     // 唯一标识（避免全局污染）
     const EVENT_HANDLER_KEY = '__ADIFRAME_CLOSE_HANDLER__';
     // 如果已存在监听函数则直接退出
     if (window[EVENT_HANDLER_KEY]) return;
    function handleCloseAdIframeMessage (event) {
        try {
            //区分广告iframe数据
            if (event.data.type === 'adIframeData') {
                const data = typeof event.data.data === 'string' ? JSON.parse(event.data.data) : event.data.data
                const action = data.action
                //判断iframe动作
                if (action === 'close') {
                    const positionId = data.positionId
                    const container = document.querySelector(`[data-pid="${positionId}"]`)
                    if (container) {
                        container.remove()
                    }
                }
            }
        } catch (e) {
            console.warn('解析消息数据失败:', e)
        }
    }
    //注册监听
    window.addEventListener('message', handleCloseAdIframeMessage);
    window[EVENT_HANDLER_KEY] = handleCloseAdIframeMessage; // 记录引用
    //注销监听
    window.addEventListener('unload', () => {
        if (window[EVENT_HANDLER_KEY]) {
            window.removeEventListener('message', window[EVENT_HANDLER_KEY]);
            delete window[EVENT_HANDLER_KEY]; // 清理标记
        }
    });
})()