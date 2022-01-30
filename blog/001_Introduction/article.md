# Journey, Part 1: Hello, World!

## Intro

Welcome to my blog.  This series of posts will serve to document my adventures building and working on my home-lab setup.

This is going to be a write-down of my experiences as I face them. It's not meant to be dealt with as a comprehensive guide and I do not consider myself to be an authority in the subjects I touch upon. Any suggestions, criticism, and comments are welcome.

## Why

I work as a DevOps/Infrastructure Engineer. I love building and strengthening infrastructure.  I don't especially like building stuff for the sake of building stuff, but I caught myself thinking, "Oh, I wish I was familiar with X tool, I wish we used it at work!" more than once.  For me, it makes complete sense to have a workbench where I can stretch and bend and break stuff to my liking, not worrying about tickets and goals and time-limits and get-things-done.

It might be novel or legacy, simple or complex, core or fluff. It's about having the opportunity to form an in-depth understanding of tooling and have fun in the process. It's also about the "cool" factor (well, nerd-cool anyway) -- I want to know that I *can* do this.

## What

At some point it's going to be a first-in-first-out queue I `push_front()` things I discover and like and `pop_back()` things to evaluate and write. For now, it's going to be way more defined. I need to have some place to host these blog entries, and I want to provide the workbench for ~~abusing~~ working with software. I think I need the following:

1. Some hardware to put stuff on
2. Some rudimentary networking in place so stuff can be available on-line
3. Some fancy way of provisioning the hardware
4. Some piece of software for orchestrating stuff
5. The blog software

Let's walk through these and, just for fun, let's do it in reverse order.

### The blog software

I've started typing this entry in markdown. I like markdown. Let's see if any FOSS blog software supports it. 

* launch firefox, google.com
* type in "blog markdown", I'm feeling lucky
* [bingo!](https://ghost.org/changelog/markdown/) Ghost supports markdown

I don't really want to overthink this. Ghost is free and open source, and it's easily replaceable as long as I keep my entries organized externally.

### Some piece of software for orchestrating stuff

No, not kubernetes. No, seriously, we're not going with kubernetes. It's not that I hate it, but I don't need the expertise with it. I've had enough of [the governor](https://translate.google.com/?sl=el&tl=en&text=%CE%BA%CF%85%CE%B2%CE%B5%CF%81%CE%BD%CE%AE%CF%84%CE%B7%CF%82&op=translate), it's not fun anymore, and it's too mainstream. Maybe in the future...  `queue.push_front("entertain possibility for some k8s grind")`

Moreover, I don't want to be fighting arcane errors that some part of the deployment automation didn't account for on whatever hardware I build on. It's either [the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way) or no way, and I'm not really feeling like the hard way. Yes, I've heard of k3s, k0s, minikube.  Having at least three distributions of some piece of software aiming for simplicity versus the other ten distributions of that piece of software is part of the problem, don't you see?

Instead, we're going to opt for the HashiStack for this job:

* [nomad](www.nomadproject.io) for orchestrating workloads
* [consul](consul.io) for service-discovery, integration with DNS for the workloads, key-value store
* [vault](www.vaultproject.io) for propagating and securing secrets

I'm going to admit it, I'm a fanboy. I love that HashiCorp embraces the [UNIX way](https://en.wikipedia.org/wiki/Unix_philosophy) and that their open-source software does not feel severely gimped compared to their enterprise offerings. I have worked extensively with nomad, consul, vault, packer, and terraform. I have had pleasant experiences with all of them.
**Nomad** will be able to orchestrate pretty much anything.
**Consul** is going to provide the framework for integrating tooling for dynamic discovery of services on the infrastructure, and it's going to be primarily operated by Nomad.
**Vault** will be the go-to for secret storage and propagation. It's extreme overkill. It's going to be so much fun!

We'll be following the [reference architecture](https://learn.hashicorp.com/tutorials/nomad/production-reference-architecture-vm-with-consul) with the exception that our servers are also going to be clients.

### Some fancy way of provisioning the hardware

If I was going for some cloud provider, I would take it a step further and define the infrastructure as code, using some IaC tooling such as [terraform](terraform.io) or [pulumi](pulumi.com). 

I'm not going to entertain that possibility. Even though comparing hardware prices and cost per KWh to cloud cost of VM instances sounds like music to my ears, I'm going to rule it as out of scope for the home-lab. Maybe in the future I'll work on it... `queue.push_front("introduce miserly cheap cloud-vm resources")`.

There are three major points in the lifecycle of the machine where configuration can be injected automatically:

1. When creating the image for the machine
2. As soon as the machine spawns by discovering configuration
3. After having the machine up and running with network available

Going exclusively for *3* is going to be way too easy, there's a plethora of Configuration-Management Tooling available, such as [ansible](ansible.com), [chef](chef.io), [puppet](puppet.com), and [saltstack](saltproject.io). It's also going to be very manual initializing a machine. Be it actual hardware or virtual, it's going to involve manual actions to install the operating system and get things started with a proper networking setup.

Going exclusively for *1* is infeasible. There *will* be dynamic configuration. So we're going to go for the tempting endeavor of going as much *1* as we can, and then *2*, ideally without any of *3*.  It's going to take some assumptions (some discovery mechanism such as internal DNS is preconfigured to bootstrap the stack), but if it works it's going to be fully hands-off other than maybe prepping some basic config when burning the image. Let's try `cloud-init` with [cloud-localds](https://readthedocs.org/projects/cloudinit/downloads/pdf/latest/) for this.

[packer](https://github.com/viralpoetry/packer-bare-metal) should be interesting, if we can use it.

### Some rudimentary networking in place so stuff can be available on-line

Let's get boring. We'll use NAT forwarding on the ISP stock router for the ports we need, and a gigabit switch. I purchased the [Netgear GS308](https://www.netgear.com/support/product/GS308.aspx).  We can expand as needed in the future.

Let's also shove DNS in this section. I've used namecheap in the past. It wasn't too terrible. Let's rent some 4-letter domains on the `.me` and the `.eu` TLDs. Done.

Cloudflare looks to be free for personal use. Let's do that for nameservers.  Any chance we can get it to do some DDoS protection for free? One can only hope; I'll postpone finding out about that when I have something concrete in place.

I realize I've probably turned off all network engineers that stumbled on this article. I'm so sorry. I promise to be better in the future.

### Some hardware to put stuff on

Finally, the fun part! I was considering the raspberry pi. It's super cheap and there is strong community around it. There's also ARM builds for all the software I'm currently considering of installing, and ARM is gaining traction and will continue to do so in the coming years. Unfortunately, at the time of writing, the RPi4 is under stock shortage, and cannot really be found for sane prices. I did a superficial search on the alternatives. I don't want to bother for now...  `queue.push_front("explore ARM-based SoCs")`

I'm kind of turned off by the idea of building the nodes from parts. I don't seem to be able to find the interesting SoC boards I could a few months back. There are some barebones, but it gets expensive as soon as you realise that even Athlon and A-series AMD chips are at the €100 mark.  I'll blame it on the chip shortage and move forward to the less get-hands-dirty solutions.

Searching for x86 Mini PCs is yielding some interesting results. There are cheap-ish solutions with quad-core celeron for around €200, with some more expensive but better equipped solutions.

| Brand      | Processor/TDP     | RAM  | Storage    | Network | Price | Link
| ---------- | -------------     | ---  | ---------- | ------- | ----- | ----
| SNUNMU     | Celeron J4125/10W | 8GB  | 128GB m.2  | 1GBps   | €210  | [link](https://www.amazon.de/-/en/Windows-Celeron-Desktop-Computer-Ethernet/dp/B09FNWK4YV)
| Minisforum | Celeron N4020/6W  | 4GB  | 64GB eMMC  | 1GBps   | €176  | [link](https://www.amazon.de/dp/B08CZ9JCJS/)
| Minisforum | Core i5 5257U/28W | 8GB  | 128GB eMMC | 1GBps   | €320  | [link](https://www.amazon.de/dp/B089CZ4QC6/)
| AWOW       | Core i3 5005U/15W | 8GB  | 128GB m.2  | 1GBps   | €230  | [link](https://www.amazon.de/dp/B07VM68GFQ/)
| AEROFARA   | Core i5 8279U/28W | 8GB  | 256GB sata | 1GBps   | €500  | [link](https://www.amazon.de/-/en/dp/B08YNJXRB7)
| WEIDIAN    | Celeron J4125/10W | 16GB | 128GB m.2  | 2x1GBps | €282  | [link](https://www.amazon.de/-/en/Celeron-Fanless-Computer-Desktop-Industrial/dp/B09D8B8WXP)
| WEIDIAN    | Celeron J4125/10W | 8GB  | 128GB m.2  | 2x1GBps | €240  | [link](https://www.amazon.de/-/en/Celeron-Fanless-Computer-Desktop-Industrial/dp/B09DCDDBXK)

As I was filling the table, the AEROFARA mini pc went up for a lightning deal down to €400, and I *had* to get one. Damn you amazon!

I'm not even sure what the WEIDIAN with 16GB is supposed to be considering the processor supports up to 8GB of RAM.

I ended up going with 3x of the SNUNMU ones in addition to the AEROFARA.

Oh, and let's get a power meter so we know how much all of this costs to run!

## Until the next time!

All-in-all, €1200 to get started is not exactly cheap, but it will hopefully make for a smooth ride towards what we want to work on.

Until the hardware arrives, I'll start preparing how to ship OS images.
