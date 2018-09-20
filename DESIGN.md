# Design decisions

## Network stack

I really wanted my generator controller to work remotely over the
network, but OpenOS had no standard networking stack at the time, and
there were 3 candidates I could use:

* Magik6k's
  [network](https://github.com/OpenPrograms/Magik6k-Programs/tree/master/network)
* Wuerfel21's
  [dispenser](https://github.com/OpenPrograms/Wuerfel_21-OC-Toolkit/tree/master/dispenser)
* [minitel](https://github.com/ShadowKatStudios/OC-Minitel/tree/master/)

### network

* Has routing.
* Looks cool, especially for its ```ifconfig```.
* Looks like the de-facto standard.
* Supports virtual addresses, i.e. arbitrary strings can be used as
  addresses so DNS is practically unnecessary.
* Interfaces can have multiple addresses.
* But has no reliable message transfer. Its TCP is actually just an
  unreliable unordered indexed stream.
* No packet segmentation based on MTU.

### dispenser

* Just a thin wrapper of the ```modem``` component.
* No routing nor reliable message transfer.

### minitel

* Has routing.
* Sounds like Newspeak.
* Uses ```/etc/hostname``` as address, so DNS is not required.
* Hosts can have only single address, which isn't cool although it
  would practically be not an issue.
* Has reliable/unreliable ordered/unordered stream/datagram message
  transfer modes. Really cool.
* Can segmentize packets based on MTU, which is essential for OC
  network cards.

So minitel was the only choice for applications that require
reliability. I didn't want my Draconic Generator to destroy the world
just because some network packets were lost.

## Protocol for draconic-energy-monitor

### RESTful API

At first I thought of doing RESTful API with RDF payloads, something
like:

```http
GET /de-energy-storages HTTP/1.1
Host: example.org
Accept: application/rdf+xml

HTTP/1.1 200 OK
Content-Type: application/rdf+xml

<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:den="http://depressed-pho.github.io/draconic-energy-monitor">
  <rdf:Description rdf:about="http://example.org/de-energy-storages">
    <den:hasEnergyStorages rdf:parseType="Collection">
      <rdf:Bag>
        <!-- List of storage addresses known to this server: -->
        <rdf:li rdf:resource="http://example.org/de-energy-storages/xxxx-xxxx-xxxx-xxxx" />
        <rdf:li rdf:resource="http://example.org/de-energy-storages/yyyy-yyyy-yyyy-yyyy" />
        <!-- ... -->
      </rdf:Bag>
    </den:hasEnergyStorages>
  </rdf:Description>
</rdf:RDF>
```

```http
GET /de-energy-storages/xxxx-xxxx-xxxx-xxxx HTTP/1.1
Host: example.org
Accept: application/rdf+xml

HTTP/1.1 200 OK
Content-Type: application/rdf+xml

<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:den="http://depressed-pho.github.io/draconic-energy-monitor">
  <rdf:Description rdf:about="http://example.org/de-energy-storages/xxxx-xxxx-xxxx-xxxx">
    <den:energyStored>1099511627776</den:energyStored><!-- RF -->
    <den:maxEnergyStored>1099511627776</den:maxEnergyStored><!-- RF -->
    <den:transferPerTick>0</den:transferPerTick><!-- RF/t -->
  </rdf:Description>
</rdf:RDF>
```

This is definitely absolutely the bestestest PERFECT SOLUTION, except
our potato computers would take ages just to perform a single RPC
call. It is simply way too ambitious for OC.

### JSON-RPC 2.0

So the next thing I thought of was
[JSON-RPC 2.0](https://www.jsonrpc.org/specification):

```
C: {"jsonrpc": "2.0", "method": "list-energy-storages", "id": 1}
S: {"jsonrpc": "2.0", "result": ["xxxx-xxxx-xxxx-xxxx", "yyyy-yyyy-yyyy-yyyy"], "id": 1}
C: {"jsonrpc": "2.0", "method": "get-energy-storage", "params": ["xxxx-xxxx-xxxx-xxxx"], "id": 2}
S: {"jsonrpc": "2.0", "result": {"energyStored": 1099511627776, ...}, "id": 2}
```

But again, this is OpenComputers. CPU time is a really, really
precious resource, and there would still be non-negligible protocol
overhead. Then what about inventing our own protocol based on
something like SMTP?

### Something like SMTP

```
S: 220 <hostname> draconic-energyd service ready
C: LIST
S: 250-xxxx-xxxx-xxxx-xxxx
S: 250 yyyy-yyyy-yyyy-yyyy
C: RETR xxxx-xxxx-xxxx-xxxx
S: 250-energyStored=1099511627776
S: 250-maxEnergyStored=1099511627776
S: 250 transferPerTick=0
C: QUIT
S: 221 <hostname> bye
<server closes the stream>
```

I hate it. **I. HATE. IT.** Because this protocol is very specific to
our particular program. No tools or libraries can be reused, even
though it would be easy to test by hand.

### Like JSON-RPC, but with our own serialization format

So here is the last resort. Let's use, ugh, the Lua-specific
serialization library inside our protocol...

```
C: {openrpc="1.0", method="list-energy-storages", id=1}
S: {openrpc="1.0", result={"xxxx-xxxx-xxxx-xxxx", "yyyy-yyyy-yyyy-yyyy"}, id=1}
C: {openrpc="1.0", method="get-energy-storage", params={"xxxx-xxxx-xxxx-xxxx"}, id=2}
S: {openrpc="1.0", result={energyStored=1099511627776, ...}, id=2}
```

I'm not happy with it **at all**, because it is never a good idea to
use such a non-standard serialization format in a protocol. But
meh... I can live with that. At least I could write a generic
server/client library and some tools to deal with it.

## OpenRPC

An RPC stack clearly needs to rely on a specific network stack, but I
really didn't want it to target only OpenOS. Because Plan9k looked so
primising.

But I obviously didn't want to reimplement it over and over for each
and every OS out there, so I decided to start with OpenOS/minitel
backend while trying to keep the OS specific portion as small as
possible.
