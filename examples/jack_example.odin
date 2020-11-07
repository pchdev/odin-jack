package main

import "jack"
import "core:time"
import "core:fmt"

// ------------------------------------------------------------------------
// quick testing
// ------------------------------------------------------------------------

acc : u32 = 0;

process_callback :: proc(nframes: jack.nframes_t, udata: rawptr) -> int {
    fmt.printf("callback, %d samples counted\n", acc);
    acc += nframes;
    return 0;
}

main :: proc()
{
    using fmt;
    using jack;

    client: jack.client_t;
    status: int;

    println("starting jack example..");
    // open client
    client = jack.client_open("odin-client", .Null, &status);
    if status > 0 {
       printf("error %d opening jack client", status);
       return;
    } else do
        println("jack client successfully opened!");

    // register a few ports
    jack.port_register(client, "in0", DEFAULT_AUDIO_TYPE, .Input, 0);
    out_port0 := jack.port_register(client, "out0", DEFAULT_AUDIO_TYPE, .Output, 0);
    sys_ports := jack.get_ports(client, "system", DEFAULT_AUDIO_TYPE, .Input);
    println("registered audio input/output ports");

    // set process callback
    jack.set_process_callback(client, process_callback);

    println("attempting to run client..");
    status = jack.activate(client);
    if status > 0 {
       println("error activating client: ", status);
       return;
    } else do
       println("client successfully activated!");

    println("attempting to connect client to system ports");
    jack.connect(client, jack.port_name(out_port0), sys_ports[0]);
    jack.connect(client, jack.port_name(out_port0), sys_ports[1]);

    println("running for 5 seconds..");
    time.sleep(time.Second*5);

    println("deactivating and closing client");
    status = jack.deactivate(client);
    status = jack.client_close(client);
    println("goodbye!");
}
