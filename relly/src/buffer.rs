use std::cell::{Cell, RefCell};
use std::collections::HashMap;
use std::io;
use std::ops::{Index, IndexMut};
use std::rc::Rc;

use crate::disk::{DiskManager, PAGE_SIZE, PageId};

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error(transparent)]
    Io(#[from] io::Error),
    #[error("no free buffer available in buffer pool")]
    NoFreeBuffer,
}

pub type Page = [u8; PAGE_SIZE];

/// Buffer has
/// - page_id: where the data this buffer has.
/// - page: actual data.
/// - is_dirty: is updated.
pub struct Buffer {
    pub page_id: PageId,
    pub page: RefCell<Page>,
    pub is_dirty: Cell<bool>,
}

/// Frame has
/// - usage_count: for eviction algorithm.
/// - buffer: actual buffer.
pub struct Frame {
    usage_count: u64,
    buffer: Rc<Buffer>,
}

pub struct BufferPool {
    buffers: Vec<Frame>,
    next_victim_id: BufferId,
}

impl BufferPool {
    /// Find usable buffer in the buffer pool.
    /// If it have free one, just return it.
    /// Otherwise try to find unreferenced buffer.
    fn evict(&mut self) -> Option<BufferId> {
        let pool_size = self.size();
        let mut consecutive_pinned = 0;

        let victim_id = loop {
            let next_victim_id = self.next_victim_id;
            let frame = &mut self[next_victim_id];
            if frame.usage_count == 0 {
                break self.next_victim_id;
            }

            // If we could optain mutable ref, it grants the buffer is not borrowed.
            // Is the trick using Rust's ownership?
            if Rc::get_mut(&mut frame.buffer).is_some() {
                frame.usage_count -= 1;
                consecutive_pinned = 0;
            } else {
                consecutive_pinned += 1;
                if consecutive_pinned >= pool_size {
                    return None;
                }
            }

            self.next_victim_id = self.increment_id(self.next_victim_id);
        };
        Some(victim_id)
    }

    /// Increment buffer id.
    /// which used for generate next buffer id.
    fn increment_id(&self, buffer_id: BufferId) -> BufferId {
        BufferId((buffer_id.0 + 1) % self.size())
    }

    /// Get buffer size.
    fn size(&self) -> usize {
        self.buffers.len()
    }
}

#[derive(Debug, Default, Clone, Copy, Eq, PartialEq, Hash)]
pub struct BufferId(usize);

impl Index<BufferId> for BufferPool {
    type Output = Frame;

    fn index(&self, index: BufferId) -> &Self::Output {
        &self.buffers[index.0]
    }
}

impl IndexMut<BufferId> for BufferPool {
    fn index_mut(&mut self, index: BufferId) -> &mut Self::Output {
        &mut self.buffers[index.0]
    }
}

/// Handle BufferPool.
pub struct BufferPoolManager {
    disk: DiskManager,
    pool: BufferPool,
    page_table: HashMap<PageId, BufferId>,
}

impl BufferPoolManager {
    /// Fetch page from buffer pool or disk.
    /// If page in buffer, then just fetch & increase usage count.
    /// Otherwise, fetch page from disk, add it to buffer pool, and return it.
    fn fetch_page(&mut self, page_id: PageId) -> Result<Rc<Buffer>, Error> {
        if let Some(&buffer_id) = self.page_table.get(&page_id) {
            let frame = &mut self.pool[buffer_id];
            frame.usage_count += 1;
            return Ok(frame.buffer.clone());
        }

        let buffer_id = self.pool.evict().ok_or(Error::NoFreeBuffer)?;
        let frame = &mut self.pool[buffer_id];
        let evict_page_id = frame.buffer.page_id;
        {
            let buffer = Rc::get_mut(&mut frame.buffer).unwrap();

            if buffer.is_dirty.get() {
                self.disk.write_page_data(evict_page_id, buffer.page.get_mut())?;
                frame.usage_count += 1;
            }
        }
        let page = Rc::clone(&frame.buffer);
        self.page_table.remove(&evict_page_id);
        self.page_table.insert(page_id, buffer_id);

        Ok(page)
    }
}
