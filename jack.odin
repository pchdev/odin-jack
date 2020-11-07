package jack
import "core:os"

when ODIN_OS == "linux" {
    foreign import jack "system:jack";
}

// note: documentation will be kept to a minimum here
// see https://jackaudio.org/api/ for the complete docs

// ------------------------------------------------------------------------
// data
// ------------------------------------------------------------------------

nframes_t    :: u32;
sample_t     :: f32;
port_id_t    :: u32;
status_t     :: int;

client_t     :: rawptr;
port_t       :: rawptr;
midi_data_t  :: rawptr;

/** Representation of a Jack MIDI event */
midi_event_t :: struct {
    time: nframes_t,        // sample index at which event is valid
    size: i64,              // number of bytes of data in buffer
    buffer: midi_data_t     // raw MIDI data
}

process_callback_t :: proc(nframes: nframes_t, udata: rawptr) -> int;

DEFAULT_AUDIO_TYPE  : cstring : "32 bit float mono audio";
DEFAULT_MIDI_TYPE   : cstring : "8 bit raw midi";

Options :: enum {
    Null            = 0x00,
    NoStartServer   = 0x01,
    UseExactName    = 0x02,
    ServerName      = 0x04,
    LoadName        = 0x08,
    LoadInit        = 0x10,
    SessionID       = 0x20
}

Port_Flags :: enum u64 {
    Input        = 0x1,
    Output       = 0x2,
    Physical     = 0x4,
    CanMonitor   = 0x8,
    IsTerminal   = 0x10
}

@(link_prefix = "jack_") foreign jack {
    /**
    * Open an external client session with a JACK server.  This interface
    * is more complex but more powerful than jack_client_new().  With it,
    * clients may choose which of several servers to connect, and control
    * whether and how to start the server automatically, if it was not
    * already running.  There is also an option for JACK to generate a
    * unique client name, when necessary. */
    client_open :: proc(name: cstring, options: Options,
                        status: ^status_t) -> client_t ---;

    /**
    * Disconnects an external client from a JACK server.
    * @return 0 on success, otherwise a non-zero error code */
    client_close :: proc(client: client_t) -> int ---;

    /**
    * Tell the Jack server that the program is ready to start processing audio.
    * @return 0 on success, otherwise a non-zero error code */
    activate :: proc(client: client_t) -> int ---;

    /**
    * Tell the Jack server to remove this @a client from the process
    * graph.  Also, disconnect all ports belonging to it, since inactive
    * clients have no port connections.
    * @return 0 on success, otherwise a non-zero error code */
    deactivate :: proc(client: client_t) -> int ---;

    /**
    * Tell the Jack server to call @a process_callback whenever there is
    * work be done, passing @a arg as the second argument.
    * NOTE: this function cannot be called while the client is activated
    * (after jack_activate has been called.)
    * @return 0 on success, otherwise a non-zero error code. */
    set_process_callback :: proc(client: client_t,
        cb: process_callback_t,
        arg: rawptr = nil) -> int ---;

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
    connect :: proc(client: client_t,
        source_port: cstring,
        destination_port: cstring) -> int ---;

    // ------------------------------------------------------------------------
    // port-related: incomplete
    // ------------------------------------------------------------------------

    /**
    * @return the full name of the jack_port_t (including the @a
    * "client_name:" prefix). */
    port_name :: proc(port: port_t) -> cstring ---;

    /**
    * Create a new port for the client. This is an object used for moving
    * data of any type in or out of the client.  Ports may be connected
    * in various ways. */
    port_register :: proc(client: client_t,
        name: cstring,
        type: cstring,
        flags: Port_Flags,
        buffer_size: u64) -> port_t ---;

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
    get_ports :: proc(client: client_t,
        port_name_pattern: cstring,
        type_name_pattern: cstring,
        flags: Port_Flags) -> []cstring ---;

    /**
    * @return address of the jack_port_t of a @a port_id. */
    port_by_id :: proc(client: client_t,
        port_id: port_id_t) -> port_t ---;

    /**
    * This returns a pointer to the memory area associated with the
    * specified port. For an output port, it will be a memory area
    * that can be written to; for an input port, it will be an area
    * containing the data from the port's connection(s), or
    * zero-filled. if there are multiple inbound connections, the data
    * will be mixed appropriately. */
    port_get_buffer :: proc(port: port_t,
        nframes: nframes_t) -> rawptr ---;

    // ------------------------------------------------------------------------
    // midi-related: incomplete
    // ------------------------------------------------------------------------

    /** Get number of events in a port buffer.
    * @param port_buffer Port buffer from which to retrieve event.
    * @return number of events inside @a port_buffer */
    midi_get_event_count :: proc(port_buffer: rawptr) -> int ---;

    /** Clear an event buffer.
    * This should be called at the beginning of each process cycle before calling
    * @ref jack_midi_event_reserve or @ref jack_midi_event_write. This
    * function may not be called on an input port's buffer.
    * @param port_buffer Port buffer to clear (must be an output port buffer). */
    midi_clear_buffer :: proc(port_buffer: rawptr) ---;


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
    midi_event_reserve :: proc(port_buffer: rawptr,
        time: nframes_t, data_size: i64) -> midi_data_t---;

    /** Get a MIDI event from an event port buffer.
    * Jack MIDI is normalised, the MIDI event returned by this function is
    * guaranteed to be a complete MIDI event (the status byte will always be
    * present, and no realtime events will interspered with the event).
    * This rule does not apply to System Exclusive MIDI messages
    * since they can be of arbitrary length.*/
    midi_event_get :: proc(event: ^midi_event_t,
        port_buffer: rawptr,
        event_index: u32) -> int ---;
}
