Introduction
============

BetterCAP is a powerful, flexible and portable tool created to perform various types of **MITM** attacks against a network, manipulate **HTTP**, **HTTPS** and **TCP** traffic in realtime, sniff for credentials and much more.

## You Are the Man in the Middle

What is a **MITM** ( *Man In The Middle* ) attack? Let's ask [Wikipedia](https://en.wikipedia.org/wiki/Man-in-the-middle_attack)!

    In cryptography and computer security, a man-in-the-middle attack (often abbreviated to MITM, MitM, MIM, MiM attack or MITMA) is an attack where the attacker secretly relays and possibly alters the communication between two parties who believe they are directly communicating with each other. Man-in-the-middle attacks can be thought about through a chess analogy.
    Mallory, who barely knows how to play chess, claims that she can play two grandmasters simultaneously and either win one game or draw both. She waits for the first grandmaster to make a move and then makes this same move against the second grandmaster. When the second grandmaster responds, Mallory makes the same play against the first. She plays the entire game this way and cannot lose.
    A man-in-the-middle attack is a similar strategy and can be used against many cryptographic protocols. One example of man-in-the-middle attacks is active eavesdropping, in which the attacker makes independent connections with the victims and relays messages between them to make them believe they are talking directly to each other over a private connection, when in fact the entire conversation is controlled by the attacker. The attacker must be able to intercept all relevant messages passing between the two victims and inject new ones. This is straightforward in many circumstances; for example, an attacker within reception range of an unencrypted Wi-Fi wireless access point, can insert himself as a man-in-the-middle.

This is quite a generic description, mostly because ( if we're talking about network MITM attacks ), the logic and details heavily rely on the technique being used ( more in the spoofing section ).

Nevertheless we can simplify the concept with an example. When you connect to some network ( your home network, some public WiFi, StarBucks, etc ), the router/switch is responsible for forwarding all of your packets to the correct destination, during a MITM attack we "force" the network to consider our device as the router ( we "spoof" the original router/switch address in some way ):

![network mitm](/_static/img/mitm.jpg)

Once this happens, all of the network traffic goes through your computer instead of the legit router/switch and at that point you can do pretty much everything you want, from just sniffing for specific data ( emails, passwords, cookies, etc of other people on your network ) to actively intercepting and proxying all the requests of some specific protocol in order to modify them on the fly ( you can, for instance, replace all images of all websites being visited by everyone, kill connections, etc ).

BetterCap is responsible for giving the security researcher everything he needs in **one single tool** which simply works, on GNU/Linux, Mac OS X and OpenBSD systems.

## Use Cases

You might think that BetterCAP is just another tool which helps script-kiddies to harm networks ... but it's much more than that, its use cases are many, for instance:

* Many professional penetration testers find a great companion in bettercap since its very first release.
* Reverse engineers are using it in order to reverse or modify closed network protocols.
* Mobile/IoT security researchers are exploiting bettercap capabilities to test the security of mobile systems.

## Why another MITM tool?

This is exactly what you are thinking right now, isn't it? :D But allow yourself to think about it for 5 more minutes ... what you should be really asking is:

> Does a complete, modular, portable and easy to extend MITM tool actually exist?

If your answer is "ettercap", let me tell you something:

* Ettercap was a great tool, but it made its time.
* Ettercap filters do not work most of the times, are outdated and hard to implement due to the specific language they're implemented in.
* Ettercap is freaking unstable on big networks ... try to launch the host discovery on a bigger network rather than the usual /24 ;)
* Yeah you can see connections and raw pcap stuff, nice toy, but as a professional researcher I want to see only relevant stuff.
* Unless you're a C/C++ developer, you can't easily extend ettercap or make your own module.

Moreover:

* Ettercap's and MITMf's ICMP spoofing is completely useless, [ours is not](http://www.evilsocket.net/2016/01/10/bettercap-and-the-first-real-icmp-redirect-attack/).
* Ettercap does **not** provide a builtin and modular HTTP(S) and TCP transparent proxies, we do.
* Ettercap does **not** provide a smart and fully customizable credentials sniffer, we do.
