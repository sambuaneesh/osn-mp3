// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
  struct run *next;
};

struct
{
  struct spinlock lock;
  struct run *freelist;
} kmem;

void kinit()
{
  initlock(&kmem.lock, "kmem");
  freerange(end, (void *)PHYSTOP);
}

int refcnt[PHYSTOP / PGSIZE];
void freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char *)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    {
      refcnt[(uint64)p / PGSIZE] = 1;
      kfree(p);
    }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.

void *JUNKFILL(void *addr, int val)
{
  // Cast the address to a char pointer, so we can work with it byte by byte
  char *byte_addr = (char *)addr;
  // Iterate over each byte in the page
  for(int i = 0; i < PGSIZE; i++)
    {
      // Set the current byte to the specified value

      byte_addr[i] = val;
    }
  // Return the original address

  return addr;
}

void *kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;

  if(r)
    {
      int pn = (uint64)r / PGSIZE;
      if(refcnt[pn] != 0)
        {
          panic("refcnt kalloc");
        }
      refcnt[pn] = 1;
      kmem.freelist = r->next;
    }

  release(&kmem.lock);

  if(r)
    {
      JUNKFILL(r, 5); // fill with junk
    }

  return (void *)r;
}

void increase_cnt(uint64 pa)
{
  int pn = pa / PGSIZE;

  acquire(&kmem.lock);

  // Check if the physical address is valid and if the reference count is at
  // least 1
  if(pa > PHYSTOP)
    {
      release(&kmem.lock);
      panic("Physical address is greater than PHYSTOP");
    }
  if(refcnt[pn] < 1)
    {
      release(&kmem.lock);
      panic("Reference count is less than 1");
    }

  // Increase the reference count
  refcnt[pn]++;

  release(&kmem.lock);
}

// function to add to freelist
void add2FL(struct run *r)
{
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

void kfree(void *pa)
{
  struct run *r = (struct run *)pa;

  // Check if the physical address is valid
  if(((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    {
      panic("Invalid physical address in kfree");
    }

  // Acquire the lock
  acquire(&kmem.lock);

  // Calculate the page number
  int pn = (uint64)r / PGSIZE;

  // Check if the reference count is at least 1
  if(refcnt[pn] < 1)
    {
      release(&kmem.lock);
      panic("Reference count is less than 1 in kfree");
    }

  // Decrease the reference count
  refcnt[pn]--;

  // Store the current reference count in a temporary variable
  int tmp = refcnt[pn];

  // Release the lock
  release(&kmem.lock);

  // If the reference count is greater than 0, return
  if(tmp > 0)
    {
      return;
    }

  // Fill with junk to catch dangling refs
  JUNKFILL(pa, 1);

  // Add to free list
  add2FL(r);
}