package com.example.human_safety

import io.flutter.plugin.common.EventChannel

object HardwareEventDispatcher {
    @JvmStatic
    var sink: EventChannel.EventSink? = null

    @JvmStatic
    fun send(event: Map<String, Any>) {
        try {
            sink?.success(event)
        } catch (t: Throwable) {
            // sink may be null if Flutter side isn't attached; ignore
        }
    }
}
