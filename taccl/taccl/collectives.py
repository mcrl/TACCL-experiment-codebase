# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from abc import ABC, abstractmethod
from dataclasses import dataclass

@dataclass
class Chunk:
    precondition: set
    postcondition: set
    address: int

@dataclass
class Rank:
    precondition: set
    postcondition: set
    id: int

class Collective:
    def __init__(self, name, num_nodes, chunks, ranks=None, triggers = {}):
        self.name = name
        self.num_nodes = num_nodes
        assert ranks is not None
        assert len(ranks) == num_nodes
        self.num_chunks = len(chunks)
        self._chunks = chunks
        self._ranks = ranks
        self._triggers = triggers

        self.is_combining = False
        addresses_seen = set()
        for chunk in self._chunks:
            if chunk.address in addresses_seen:
                self.is_combining = True
            addresses_seen.add(chunk.address)
        self.num_addresses = len(addresses_seen)

    def ranks(self):
        return range(self.num_nodes)

    def chunks(self):
        return range(len(self._chunks))

    def precondition(self, rank, chunk):
        return rank in self._chunks[chunk].precondition

    def postcondition(self, rank, chunk):
        # TCCL
        print(f"TCCL: postcondition rank: {rank}, chunk: {chunk}, self._chunks[chunk].postcondition: {self._chunks[chunk].postcondition}")
        #
        return rank in self._chunks[chunk].postcondition

    def address(self, chunk):
        return self._chunks[chunk].address

    def trigger(self, rank, chunk):
        if (rank, chunk) in self._triggers:
            return self._triggers[(rank, chunk)]
        else:
            return None

    def pre_rank(self, chunk):
        return self._chunks[chunk].precondition

    def post_rank(self, chunk):
        return self._chunks[chunk].postcondition

    def pre_chunk(self, rank):
        """ TCCL"""
        print("ranks: ", self._ranks)
        print("pre_chunk rank: ", rank)
        print("precondition: ", self._ranks[rank].precondition)
        return self._ranks[rank].precondition

    def post_chunk(self, rank):
        return self._ranks[rank].postcondition

    def has_triggers(self):
        return len(self._triggers) > 0

    def chunk_up(self, div):
        if div < 1:
            raise ValueError('Divisor must be greater or equal to one (and one is a no-op).')
        if div == 1:
            return self

        def remap(addr, i):
            return addr * div + i

        new_chunks = []
        new_ranks = []
        for chunk in self._chunks:
            for i in range(div):
                new_chunks.append(Chunk(chunk.precondition, chunk.postcondition, remap(chunk.address, i)))
        for rank in self._ranks:
            new_rank_precondition = set(remap(chunk, i) for i in range(div) for chunk in rank.precondition)
            new_rank_postcondition = set(remap(chunk, i) for i in range(div) for chunk in rank.postcondition)
            new_ranks.append(Rank(new_rank_precondition, new_rank_postcondition, rank))

        name = f'{self.name},chunks={div}'
        return Collective(name, self.num_nodes, new_chunks, new_ranks)

    def __str__(self):
        collstr = "{}\n \t num_nodes: {}\n \t num_chunks: {}".format(self.name, self.num_nodes, self.num_chunks)
        return collstr

def build_collective(name, num_nodes, num_chunks, precondition, postcondition, address = lambda c: c, trigger = lambda r, c: None):
    chunks = []
    ranks = []
    print(f"TCCL: build_collective: {locals()}")
    for chunk in range(num_chunks):
        chunk_precondition = set(rank for rank in range(num_nodes) if precondition(rank, chunk))
        chunk_postcondition = set(rank for rank in range(num_nodes) if postcondition(rank, chunk))
        chunk_address = address(chunk)
        chunks.append(Chunk(chunk_precondition, chunk_postcondition, chunk_address))
        print(f"TCCL: build_collective: chunk({chunk}) {chunks[-1]}")
    for rank in range(num_nodes):
        rank_precondition = set(chunk for chunk in range(num_chunks) if precondition(rank, chunk))
        rank_postcondition = set(chunk for chunk in range(num_chunks) if postcondition(rank, chunk))
        ranks.append(Rank(rank_precondition, rank_postcondition, rank))
    triggers = {(rank, chunk): trigger(rank, chunk) for rank in range(num_nodes) for chunk in range(num_chunks) if trigger(rank, chunk) != None}
    return Collective(name, num_nodes, chunks, ranks, triggers)

# Common pre- and postconditions
def _scattered(num_nodes, chunks = 1):
    def cond(rank, chunk):
        return rank == (chunk // chunks) % num_nodes
    return cond

def _transpose(num_nodes):
    def cond(rank, chunk):
        return rank == chunk // num_nodes
    return cond

def _all(rank, chunk):
    return True

def _root(root):
    def cond(rank, chunk):
        return rank == root
    return cond

# Non-combining collectives

def broadcast(num_nodes, root):
    return build_collective(f'Broadcast(n={num_nodes},root={root})', num_nodes, 1, _root(root), _all)

def scatter(num_nodes, root):
    return build_collective(f'Scatter(n={num_nodes},root={root})', num_nodes, num_nodes, _root(root), _scattered(num_nodes))

def gather(num_nodes, root):
    return build_collective(f'Gather(n={num_nodes},root={root})', num_nodes, num_nodes, _scattered(num_nodes), _root(root))

def allgather(num_nodes):
    return build_collective(f'Allgather(n={num_nodes})', num_nodes, num_nodes, _scattered(num_nodes), _all)

def alltoall(num_nodes):
    return build_collective(f'Alltoall(n={num_nodes})', num_nodes, num_nodes * num_nodes, _scattered(num_nodes), _transpose(num_nodes))

# Combining collectives

# Represents a single buffer to reduce
def _single_scattered(num_nodes):
    def address(chunk):
        return chunk // num_nodes
    return address

def reduce(num_nodes, root):
    return build_collective(f'Reduce(n={num_nodes},root={root})', num_nodes, num_nodes, _scattered(num_nodes), _root(root), _single_scattered(num_nodes))

def allreduce(num_nodes):
    return build_collective(f'Allreduce(n={num_nodes})', num_nodes, num_nodes, _scattered(num_nodes), _all, _single_scattered(num_nodes))

def reduce_scatter(num_nodes):
    return build_collective(f'ReduceScatter(n={num_nodes})', num_nodes, num_nodes * num_nodes, _scattered(num_nodes), _transpose(num_nodes), _single_scattered(num_nodes))

def scan(num_nodes):
    def postcondition(rank, chunk):
        origin = chunk % num_nodes
        return rank >= origin
    return build_collective(f'Scan(n={num_nodes})', num_nodes, num_nodes, _scattered(num_nodes), postcondition, _single_scattered(num_nodes))

# Multi-root generalizations of MPI rooted collectives
# TODO: Add one for reduce. That needs a new addressing function.

def _roots(roots):
    def cond(rank, chunk):
        return rank == roots[chunk % len(roots)]
    return cond

def multiroot_broadcast(num_nodes, roots):
    return build_collective(f'MultirootBroadcast(n={num_nodes},roots=({",".join(str(i) for i in roots)}))', num_nodes, len(roots), _roots(roots), _all)

def multiroot_scatter(num_nodes, roots):
    return build_collective(f'MultirootScatter(n={num_nodes},roots=({",".join(str(i) for i in roots)}))', num_nodes, num_nodes * len(roots), _roots(roots), _scattered(num_nodes, len(roots)))

def multiroot_gather(num_nodes, roots):
    return build_collective(f'MultirootGather(n={num_nodes},roots=({",".join(str(i) for i in roots)}))', num_nodes, num_nodes * len(roots), _scattered(num_nodes, len(roots)), _roots(roots))
