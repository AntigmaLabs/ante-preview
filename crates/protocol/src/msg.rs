use std::collections::HashMap;
use std::path::PathBuf;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::id::Id;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EventMsg {
    pub timestamp: DateTime<Utc>,
    pub id: Id,
    pub event: Evt,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent: Option<Id>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpMsg {
    pub op: Op,
    pub id: Id,
}

#[allow(clippy::large_enum_variant)]
#[derive(Debug, Clone, Deserialize, Serialize)]
pub enum Op {
    StartSession(SessionConfig),
    UpdateSession(SessionUpdate),
    Interrupt,
    UserInput(String),
    Steer(String),
    ApprovalResponse { turn_id: Id, responses: Vec<(String, ReviewDecision)> },
    SlashCommand { name: String, args: String },
    ResumeSession { session_id: Id },
    OfflineMode(OfflineModeOp),
    Shutdown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Evt {
    SessionStart(Box<SessionInitialized>),
    SessionUpdated(Box<SessionInitialized>),
    ExtensionRefreshed(Box<ExtensionRefreshed>),
    SessionEnd,
    UserInput(String),
    AgentMessage(String),
    Thinking(String),
    MessageDelta(String),
    ThinkingDelta(String),
    Info(String),
    Error(String),
    ToolStart(ToolUse),
    ToolUpdate(ToolUpdate),
    ToolEnd(ToolEnd),
    CompactStart,
    CompactEnd,
    TurnStart { turn_id: Id },
    TurnPause { turn_id: Id, reason: TurnPauseReason },
    TurnEnd { turn_id: Id, status: TurnEndStatus },
    UsageUpdate { usage: Usage },
    OfflineMode(OfflineModeEvt),
    Goodbye,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TurnPauseReason {
    Approval { tools: Vec<ToolUse>, message: String },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TurnEndStatus {
    Completed,
    Interrupted {
        #[serde(skip_serializing_if = "Option::is_none")]
        reason: Option<String>,
    },
    Error {
        message: String,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolUpdate {
    pub tool_use_id: String,
    pub seq: u64,
    pub message: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ToolEndStatus {
    Completed,
    Cancelled,
    Denied,
    Failed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolEnd {
    pub tool_use_id: String,
    pub status: ToolEndStatus,
    pub result_json: serde_json::Value,
    pub is_error: bool,
}

impl ToolEnd {
    pub fn tool_use_id(&self) -> &str {
        &self.tool_use_id
    }

    pub fn is_error(&self) -> bool {
        self.is_error
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ReviewDecision {
    Accept,
    Skip,
    AcceptForSession,
    Abort,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillMetadata {
    pub name: String,
    pub description: Option<String>,
    pub scope: Scope,
    pub argument_hint: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubagentMetadata {
    pub name: String,
    pub description: String,
    pub color: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionInitialized {
    pub model: ModelSpec,
    pub provider: ApiProvider,
    pub session_id: Id,
    pub cwd: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionUpdate {
    pub model: ModelSpec,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtensionRefreshed {
    pub session_id: Id,
    pub skills: Vec<SkillMetadata>,
    pub subagents: Vec<SubagentMetadata>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OfflineModeOp {
    Init,
    InstallEngine,
    UpgradeEngine,
    SetModelDirectory { path: PathBuf },
    LoadModel { model: OfflineModel, prefs: ModelPreferences },
    StopServer,
    AttachServer { port: u16, model_name: String },
    KillLlamaServer,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OfflineModeEvt {
    Init {
        engine_status: EngineStatus,
        system_caps: SystemCapabilities,
        local_models: Vec<OfflineModel>,
        verified_models: Vec<VerifiedModel>,
        #[serde(default)]
        upgrade_available: Option<(Option<u32>, u32)>,
        #[serde(default)]
        running_servers: Vec<RunningServer>,
    },
    InstallProgress {
        progress: u8,
        message: String,
    },
    Installed {
        path: PathBuf,
    },
    ModelLoading {
        model_name: String,
        file_size_bytes: u64,
    },
    ServerReady {
        port: u16,
        model_name: String,
        #[serde(default)]
        server_pid: Option<u32>,
    },
    LlamaServerKilled,
    Error {
        message: String,
    },
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SessionConfig {
    pub model: String,
    pub provider: String,
    pub policy: Option<PermissionMode>,
    pub streaming: bool,
    pub system_prompt: Option<String>,
    pub append_system_prompt: Option<String>,
    pub allowed_tools: Option<Vec<String>>,
    pub disallowed_tools: Option<Vec<String>>,
    pub cwd: Option<PathBuf>,
}

impl SessionConfig {
    pub fn default_streaming_enabled() -> bool {
        std::env::var("ANTE_DISABLE_STREAMING").is_err()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolUse {
    pub id: String,
    pub name: String,
    pub args: serde_json::Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub signature: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelSpec {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_p: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_k: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_tokens: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stop_sequences: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context_limit: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub thinking: Option<Thinking>,
}

impl ModelSpec {
    pub fn new(name: String) -> Self {
        Self {
            name,
            description: None,
            temperature: None,
            top_p: None,
            top_k: None,
            max_tokens: None,
            stop_sequences: None,
            thinking: None,
            context_limit: None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Copy, PartialEq)]
pub enum Thinking {
    Disabled,
    Enabled,
    Deep,
    Max,
}

#[derive(Debug, Clone, Deserialize, Serialize, Default, Copy)]
#[serde(default)]
pub struct Usage {
    pub input_tokens: u32,
    pub output_tokens: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cache_read_tokens: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cache_creation_tokens: Option<u32>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq, Eq)]
pub enum WireStyle {
    #[default]
    AnthropicMessage,
    OpenAiCompatible,
    OpenAiResponse,
    Gemini,
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
pub struct ApiProvider {
    pub name: String,
    pub display_name: String,
    pub base_url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auth: Option<AuthConfig>,
    pub wire_style: WireStyle,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub http_headers: Option<HashMap<String, String>>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub preferred_models: Vec<ModelSpec>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AuthConfig {
    Bearer {
        #[serde(flatten)]
        credential: CredentialRef,
    },
    Header {
        name: String,
        #[serde(flatten)]
        credential: CredentialRef,
    },
    Query {
        name: String,
        #[serde(flatten)]
        credential: CredentialRef,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CredentialRef {
    EnvKey(String),
    #[serde(rename = "oauth_preset")]
    OAuthPreset(OAuthPresetId),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OAuthPresetId {
    Anthropic,
    #[serde(rename = "openai", alias = "open_ai")]
    OpenAi,
    Antix,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, Default, Eq, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum PermissionMode {
    #[default]
    Default,
    Yolo,
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
#[serde(rename_all = "kebab-case")]
pub enum Scope {
    Project,
    User,
    System,
    Agent,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RunningServer {
    pub port: u16,
    pub model_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OfflineModel {
    pub file_name: String,
    pub file_size_bytes: u64,
    #[serde(default)]
    pub kv_cache_bytes_per_token: u64,
    pub source: ModelSource,
    #[serde(default = "default_context_window")]
    pub context_window: u32,
    #[serde(default = "default_shard_count")]
    pub shard_count: u32,
    #[serde(default)]
    pub display_name: Option<String>,
}

fn default_shard_count() -> u32 {
    1
}

fn default_context_window() -> u32 {
    32768
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ModelSource {
    Local(PathBuf),
    Verified { repo: String, url: String },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelPreferences {
    pub model_id: String,
    pub context_window: u32,
    pub thinking_enabled: bool,
    pub temperature: Option<f32>,
    #[serde(default)]
    pub last_used: u64,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SystemCapabilities {
    pub total_ram_mb: u64,
    pub available_ram_mb: u64,
    pub gpu_devices: Vec<GpuDevice>,
    pub total_vram_mb: u64,
    pub available_vram_mb: u64,
    #[serde(default)]
    pub is_unified_memory: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GpuDevice {
    pub index: u32,
    pub name: String,
    pub vram_mb: u64,
    pub compute_capability: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum EngineStatus {
    Installed { server_path: PathBuf, cli_path: PathBuf },
    NotInstalled,
    Installing { progress: u8, message: String },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerifiedModel {
    pub name: String,
    pub repo: String,
    pub filename: String,
    pub context_window: u32,
    pub file_size_mb: u64,
    pub kv_cache_bytes_per_token: u64,
}

#[cfg(test)]
mod tests {
    use super::{
        ApiProvider, EngineStatus, Evt, Id, ModelSource, ModelSpec, OfflineModeEvt, OfflineModel,
        Op, SessionInitialized, SessionUpdate, SystemCapabilities, VerifiedModel,
    };
    use std::path::PathBuf;

    #[test]
    fn compact_events_serde_roundtrip() {
        let compact_start =
            serde_json::to_string(&Evt::CompactStart).expect("serialize CompactStart");
        let compact_end = serde_json::to_string(&Evt::CompactEnd).expect("serialize CompactEnd");

        assert_eq!(compact_start, "\"CompactStart\"");
        assert_eq!(compact_end, "\"CompactEnd\"");

        assert!(matches!(
            serde_json::from_str::<Evt>(&compact_start).expect("deserialize CompactStart"),
            Evt::CompactStart
        ));
        assert!(matches!(
            serde_json::from_str::<Evt>(&compact_end).expect("deserialize CompactEnd"),
            Evt::CompactEnd
        ));
    }

    #[test]
    fn session_update_op_serde_roundtrip() {
        let op = Op::UpdateSession(SessionUpdate {
            model: ModelSpec {
                name: "gpt-5.4".to_string(),
                temperature: Some(0.2),
                ..ModelSpec::new("gpt-5.4".to_string())
            },
        });

        let json = serde_json::to_string(&op).expect("serialize UpdateSession");
        let decoded = serde_json::from_str::<Op>(&json).expect("deserialize UpdateSession");

        assert!(matches!(
            decoded,
            Op::UpdateSession(SessionUpdate { model })
                if model.name == "gpt-5.4" && model.temperature == Some(0.2)
        ));
    }

    #[test]
    fn session_updated_event_serde_roundtrip() {
        let session_id = Id::new("ses");
        let event = Evt::SessionUpdated(Box::new(SessionInitialized {
            model: ModelSpec::new("claude-sonnet-4-6".to_string()),
            provider: ApiProvider::default(),
            session_id,
            cwd: PathBuf::from("/tmp/session-updated"),
        }));

        let json = serde_json::to_string(&event).expect("serialize SessionUpdated");
        let decoded = serde_json::from_str::<Evt>(&json).expect("deserialize SessionUpdated");

        assert!(matches!(
            decoded,
            Evt::SessionUpdated(payload)
                if payload.model.name == "claude-sonnet-4-6"
                    && payload.session_id == session_id
                    && payload.cwd == std::path::Path::new("/tmp/session-updated")
        ));
    }

    #[test]
    fn offline_mode_event_serde_roundtrip() {
        let event = Evt::OfflineMode(OfflineModeEvt::Init {
            engine_status: EngineStatus::Installing {
                progress: 40,
                message: "installing".to_string(),
            },
            system_caps: SystemCapabilities {
                total_ram_mb: 32768,
                available_ram_mb: 16384,
                gpu_devices: Vec::new(),
                total_vram_mb: 0,
                available_vram_mb: 0,
                is_unified_memory: true,
            },
            local_models: vec![OfflineModel {
                file_name: "model.gguf".to_string(),
                file_size_bytes: 1024,
                kv_cache_bytes_per_token: 256,
                source: ModelSource::Local(PathBuf::from("/models/model.gguf")),
                context_window: 32768,
                shard_count: 1,
                display_name: Some("Local Model".to_string()),
            }],
            verified_models: vec![VerifiedModel {
                name: "Verified Model".to_string(),
                repo: "org/model".to_string(),
                filename: "verified.gguf".to_string(),
                context_window: 65536,
                file_size_mb: 4096,
                kv_cache_bytes_per_token: 1024,
            }],
            upgrade_available: Some((Some(8030), 8038)),
            running_servers: Vec::new(),
        });

        let json = serde_json::to_string(&event).expect("serialize OfflineModeEvt::Init");
        let decoded = serde_json::from_str::<Evt>(&json).expect("deserialize OfflineModeEvt::Init");

        assert!(matches!(
            decoded,
            Evt::OfflineMode(OfflineModeEvt::Init {
                upgrade_available: Some((Some(8030), 8038)),
                ..
            })
        ));
    }
}
