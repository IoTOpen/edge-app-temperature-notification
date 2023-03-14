local armed = {}
local topicFunctionMap = {}
local lastMsgs = {}

function outsideOfParameters(value)
    if cfg.overOrUnder == "over" then
        if value > cfg.threshold then return true end
    else
        if value < cfg.threshold then return true end
    end
    return false
end

function notify(fn, msg, topic)
    local payloadData = {
        ["function"] = fn,
        ["msg"] = msg,
        ["last_msg"] = lastMsgs[topic],
        ["threshold"] = cfg.threshold,
    }
    lynx.notify(cfg.notificationOutput, payloadData)
end

function ping(topic, fn, msg)
    if armed[topic] == nil then
        armed[topic] = timer:after(cfg.delay * 60, function()
            notify(fn, msg, topic)
            armed[topic] = nil
        end)
    end
end

function cancel(topic)
    local alarm = armed[topic]
    if alarm ~= nil then
        alarm:cancel()
        armed[topic] = nil
    end
end

function handleValue(topic, payload, retained)
    if retained then return end
    local msg = json:decode(payload)
    lastMsgs[topic] = msg
    if outsideOfParameters(msg.value) then
        if cfg.delay == 0 then
            notify(topicFunctionMap[topic], msg, topic)
        else
            ping(topic, topicFunctionMap[topic], msg)
        end
    else
        cancel(topic)
    end
end

function onFunctionsUpdated()
    for topic, _ in pairs(topicFunctionMap) do
        mq:unsub(topic)
        mq:unbind(topic, handleValue)
    end
    local fns = edge.findFunctions(cfg.functions)
    for _, fn in ipairs(fns) do
        if fn.meta.topic_read ~= nil then
            topicFunctionMap[fn.meta.topic_read] = fn
            mq:sub(fn.meta.topic_read, 0)
            mq:bind(fn.meta.topic_read, handleValue)
        end
    end
end

function onStart()
    local fns = edge.findFunctions(cfg.functions)
    for _, fn in ipairs(fns) do
        if fn.meta.topic_read ~= nil then
            topicFunctionMap[fn.meta.topic_read] = fn
            mq:sub(fn.meta.topic_read, 0)
            mq:bind(fn.meta.topic_read, handleValue)
        end
    end
end