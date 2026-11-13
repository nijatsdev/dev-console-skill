package com.example.kite

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Text
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.status.SessionStatus

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val status by supabase.auth.sessionStatus.collectAsState()
            when (val s = status) {
                is SessionStatus.Authenticated -> Text("Hi ${s.session.user?.email}")
                else -> Text("Signed out")
            }
        }
    }
}
