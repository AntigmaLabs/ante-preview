use std::sync::{Mutex, MutexGuard};

pub mod buffer;
pub mod handle;
pub mod pool;
pub mod process_group;
pub mod receiver;
pub mod subprocess;

pub use buffer::HeadTailBuffer;
pub use handle::{OutputChunk, ProcessHandle, SpawnedProcess, Stream};
pub use pool::{
    ExecError, ExecRequest, ExecResponse, PollRequest, PoolConfig, ProcessPool, StdinRequest,
};
pub use receiver::OutputReceiver;
pub use subprocess::{CommandOptions, RunOutput, StdinMode, run_with_timeout};

pub(crate) fn lock_or_recover<T>(mutex: &Mutex<T>) -> MutexGuard<'_, T> {
    match mutex.lock() {
        Ok(guard) => guard,
        Err(poisoned) => poisoned.into_inner(),
    }
}

#[cfg(test)]
mod tests;
