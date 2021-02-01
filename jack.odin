package jack
import "core:os"

when ODIN_OS == "linux" {
    foreign import jack "system:jack";
}

import "core:c"

// note: documentation will be kept to a minimum here
// see https://jackaudio.org/api/ for the complete docs

// ------------------------------------------------------------------------
// data
// ------------------------------------------------------------------------

nframes_t    :: u32;
sample_t     :: f32;
port_id_t    :: u32;
status_t     :: c.int;
client_t     :: distinct rawptr;
port_t       :: distinct rawptr;
midi_data_t  :: distinct rawptr;

/** Representation of a Jack MIDI event */
midi_event_t :: struct {
    time: nframes_t,        // sample index at which event is valid
    size: i64,              // number of bytes of data in buffer
    buffer: midi_data_t     // raw MIDI data
}

process_callback :: proc(nframes: nframes_t, udata: rawptr) -> c.int;
port_connect_callback :: proc(a: port_id_t, b: port_id_t, connect: c.int, udata: rawptr);
buffer_size_callback :: proc(nframes: nframes_t, udata: rawptr) -> c.int;

DEFAULT_AUDIO_TYPE: cstring : "32 bit float mono audio";
DEFAULT_MIDI_TYPE: cstring : "8 bit raw midi";

Options :: enum {
           Null = 0x00,
No_Start_Server = 0x01,
 Use_Exact_Name = 0x02,
    Server_Name = 0x04,
      Load_Name = 0x08,
      Load_Init = 0x10,
     Session_ID = 0x20
}

Port_Flags :: enum u64 {
         Input = 0x1,
        Output = 0x2,
      Physical = 0x4,
   Can_Monitor = 0x8,
   Is_Terminal = 0x10
}

// ------------------------------------------------------------------------
// procedures
// ------------------------------------------------------------------------

foreign jack {
    /**
    * Open an external client session with a JACK server.  This interface
    * is more complex but more powerful than jack_client_new().  With it,
    * clients may choose which of several servers to connect, and control
    * whether and how to start the server automatically, if it was not
    * already running.  There is also an option for JACK to generate a
    * unique client name, when necessary. */
    @(link_name = "jack_client_open")
    open_client :: proc (
           name: cstring,
        options: Options = .Null,
         status: ^status_t = nil) -> client_t ---;

    /**
    * Disconnects an external client from a JACK server.
    * @return 0 on success, otherwise a non-zero error code */
    @(link_name = "jack_client_close")
    close_client :: proc(client: client_t) -> c.int ---;

    /**
    * Tell the Jack server that the program is ready to start processing audio.
    * @return 0 on success, otherwise a non-zero error code */
    @(link_name = "jack_activate")
    activate :: proc(client: client_t) -> c.int ---;

    /**
    * Tell the Jack server to remove this @a client from the process
    * graph.  Also, disconnect all ports belonging to it, since inactive
    * clients have no port connections.
    * @return 0 on success, otherwise a non-zero error code */
    @(link_name = "jack_deactivate")
    deactivate :: proc(client: client_t) -> c.int ---;

    /**
    * Tell the Jack server to call @a process_callback whenever there is
    * work be done, passing @a arg as the second argument.
    * NOTE: this function cannot be called while the client is activated
    * (after jack_activate has been called.)
    * @return 0 on success, otherwise a non-zero error code. */
    @(link_name = "jack_set_process_callback")
    set_process_callback :: proc (
        client: client_t,
            cb: process_callback,
           arg: rawptr = nil) -> c.int ---;

    /**
    * Tell JACK to call @a bufsize_callback whenever the size of the the
    * buffer that will be passed to the @a process_callback is about to
    * change.  Clients that depend on knowing the buffer size must supply
    * a @a bufsize_callback before activating themselves.
    *
    * All "notification events" are received in a separated non RT thread,
    * the code in the supplied function does not need to be
    * suitable for real-time execution.
    *
    * NOTE: this function cannot be called while the client is activated
    * (after jack_activate has been called.)
    *
    * @param client pointer to JACK client structure.
    * @param bufsize_callback function to call when the buffer size changes.
    * @param arg argument for @a bufsize_callback.
    *
    * @return 0 on success, otherwise a non-zero error code
    */
    @(link_name = "jack_set_buffer_size_callback")
    set_buffer_size_callback :: proc (
        client: client_t,
            cb: buffer_size_callback,
           arg: rawptr = nil) -> c.int ---;

    /**
    * Establish a connection between two ports.
    * When a connection exists, data written to the source port will
    * be available to be read at the destination port.
    * @pre The port types must be identical.
    * @pre The @ref JackPortFlags of the @a source_port must include @ref
    * JackPortIsOutput.
    * @pre The @ref JackPortFlags of the @a destination_port must include
    * @ref JackPortIsInput.
    *
    * @return 0 on success, EEXIST if the connection is already made,
    * otherwise a non-zero error code */
    @(link_name = "jack_connect")
    connect :: proc(
              client: client_t,
         source_port: cstring,
    destination_port: cstring) -> c.int ---;

    // ------------------------------------------------------------------------
    // port-related: incomplete
    // ------------------------------------------------------------------------

    /**
    * @return the full name of the jack_port_t (including the @a
    * "client_name:" prefix). */
    @(link_name = "jack_port_name")
    port_name :: proc(port: port_t) -> cstring ---;

    /**
    * Create a new port for the client. This is an object used for moving
    * data of any type in or out of the client.  Ports may be connected
    * in various ways. */
    @(link_name = "jack_port_register")
    register_port :: proc (
             client: client_t,
               name: cstring,
               type: cstring,
              flags: Port_Flags,
        buffer_size: u64 = 0) -> port_t ---;

    /**
    * Tell the JACK server to call @a connect_callback whenever a
    * port is connected or disconnected, passing @a arg as a parameter.
    *
    * All "notification events" are received in a separated non RT thread,
    * the code in the supplied function does not need to be
    * suitable for real-time execution.
    *
    * NOTE: this function cannot be called while the client is activated
    * (after jack_activate has been called.)
    *
    * @return 0 on success, otherwise a non-zero error code
    */
    @(link_name = "jack_set_port_connect_callback")
    set_port_connect_callback :: proc(
          client: client_t,
        callback: port_connect_callback,
           udata: rawptr) -> c.int ---;

    /**
    * @param port_name_pattern A regular expression used to select
    * ports by name.  If NULL or of zero length, no selection based
    * on name will be carried out.
    * @param type_name_pattern A regular expression used to select
    * ports by type.  If NULL or of zero length, no selection based
    * on type will be carried out.
    * @param flags A value used to select ports by their flags.
    * If zero, no selection based on flags will be carried out.
    * @return a NULL-terminated array of ports that match the specified
    * arguments.  The caller is responsible for calling jack_free() any
    * non-NULL returned value. */
    @(link_name = "jack_get_ports")
    get_ports :: proc (
               client: client_t,
    port_name_pattern: cstring,
    type_name_pattern: cstring,
                flags: Port_Flags) -> ^cstring ---;

    /**
    * @return address of the jack_port_t of a @a port_id. */
    @(link_name = "jack_port_by_id")
    port_by_id :: proc (
         client: client_t,
        port_id: port_id_t) -> port_t ---;

    /**
    * This returns a pointer to the memory area associated with the
    * specified port. For an output port, it will be a memory area
    * that can be written to; for an input port, it will be an area
    * containing the data from the port's connection(s), or
    * zero-filled. if there are multiple inbound connections, the data
    * will be mixed appropriately. */
    @(link_name = "jack_port_get_buffer")
    get_port_buffer :: proc (
           port: port_t,
        nframes: nframes_t) -> rawptr ---;

    // ------------------------------------------------------------------------
    // midi-related: incomplete
    // ------------------------------------------------------------------------

    /** Get number of events in a port buffer.
    * @param port_buffer Port buffer from which to retrieve event.
    * @return number of events inside @a port_buffer */
    @(link_name = "jack_midi_get_event_count")
    midi_event_count :: proc(port_buffer: rawptr) -> c.int ---;

    /** Clear an event buffer.
    * This should be called at the beginning of each process cycle before calling
    * @ref jack_midi_event_reserve or @ref jack_midi_event_write. This
    * function may not be called on an input port's buffer.
    * @param port_buffer Port buffer to clear (must be an output port buffer). */
    @(link_name = "jack_midi_clear_buffer")
    clear_midi_buffer :: proc(port_buffer: rawptr) ---;

    /** Allocate space for an event to be written to an event port buffer.
    * Clients are to write the actual event data to be written starting at the
    * pointer returned by this function. Clients must not write more than
    * @a data_size bytes into this buffer.  Clients must write normalised
    * MIDI data to the port - no running status and no (1-byte) realtime
    * messages interspersed with other messages (realtime messages are fine
    * when they occur on their own, like other messages).
    * Events must be written in order, sorted by their sample offsets.
    * JACK will not sort the events for you, and will refuse to store
    * out-of-order events. */
    @(link_name = "jack_midi_event_reserve")
    reserve_midi_event :: proc (
        port_buffer: rawptr,
               time: nframes_t,
          data_size: i64) -> midi_data_t---;

    /** Get a MIDI event from an event port buffer.
    * Jack MIDI is normalised, the MIDI event returned by this function is
    * guaranteed to be a complete MIDI event (the status byte will always be
    * present, and no realtime events will interspered with the event).
    * This rule does not apply to System Exclusive MIDI messages
    * since they can be of arbitrary length.*/
    @(link_name = "jack_midi_event_get")
    get_midi_event :: proc (
              event: ^midi_event_t,
        port_buffer: rawptr,
        event_index: u32) -> c.int ---;
}
