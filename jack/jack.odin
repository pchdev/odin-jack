package jack
import "core:os"

when ODIN_OS == "linux" {
    foreign import jack "system:jack";
}

// ------------------------------------------------------------------------
// data
// ------------------------------------------------------------------------

nframes_t  :: u32;
sample_t   :: f32;
port_id_t  :: u32;
status_t   :: int;

client_t     :: rawptr;
port_t       :: rawptr;
midi_data_t  :: rawptr;

midi_event_t :: struct {
    time: nframes_t,
    size: i64,
    buffer: midi_data_t
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
    // ------------------------------------------------------------------------
    // general procedures
    // ------------------------------------------------------------------------

    client_open   :: proc(name: cstring, options: Options,
                         status: ^status_t) -> client_t ---;
    client_close  :: proc(client: client_t) -> int ---;
    activate      :: proc(client: client_t) -> int ---;
    deactivate    :: proc(client: client_t) -> int ---;

    set_process_callback :: proc(client: client_t,
        cb: process_callback_t) -> int ---;

    connect :: proc(client: client_t,
        source_port: cstring,
        destination_port: cstring) -> int ---;

    // ------------------------------------------------------------------------
    // port-related: todo
    // ------------------------------------------------------------------------

    port_name :: proc(port: port_t) -> cstring ---;

    port_register :: proc(client: client_t,
        name: cstring,
        type: cstring,
        flags: Port_Flags,
        buffer_size: u64) -> port_t ---;

    get_ports :: proc(client: client_t,
        port_name_pattern: cstring,
        type_name_pattern: cstring,
        flags: Port_Flags) -> []cstring ---;

    port_by_id :: proc(client: client_t,
        port_id: port_id_t) -> port_t ---;

    port_get_buffer :: proc(port: port_t,
        nframes: nframes_t) -> rawptr ---;

    // ------------------------------------------------------------------------
    // midi-related: todo
    // ------------------------------------------------------------------------

    midi_get_event_count :: proc(port_buffer: rawptr) -> int ---;
    midi_clear_buffer :: proc(port_buffer: rawptr) ---;

    midi_event_reserve :: proc(port_buffer: rawptr,
        time: nframes_t, data_size: i64) -> midi_data_t---;

    midi_event_get :: proc(event: ^midi_event_t,
        port_buffer: rawptr,
        event_index: u32) -> int ---;
}
