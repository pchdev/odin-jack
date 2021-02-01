package main

import jack ".."
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
    
    client: client_t;
    status: int;

    println("starting jack example..");
    // open client
    client = open_client("odin-client", .Null, &status);
    if status > 0 {
       printf("error %d opening jack client", status);
       return;
    } else do
        println("jack client successfully opened!");

    // register a few ports
    register_port(client, "in0", DEFAULT_AUDIO_TYPE, .Input);
    out_port0 := register_port(client, "out0", DEFAULT_AUDIO_TYPE, .Output);
    sys_ports := get_ports(client, "system", DEFAULT_AUDIO_TYPE, .Input);
    println("registered audio input/output ports");

    // set process callback
    set_process_callback(client, process_callback);

    println("attempting to run client..");
    status = activate(client);
    if status > 0 {
       println("error activating client: ", status);
       return;
    } else do
       println("client successfully activated!");

    println("attempting to connect client to system ports");
    connect(client, port_name(out_port0), sys_ports[0]);
    connect(client, port_name(out_port0), sys_ports[1]);

    println("running for 5 seconds..");
    time.sleep(5 * time.Second);

    println("deactivating and closing client");
    status = deactivate(client);
    status = close_client(client);
    println("goodbye!");
}
