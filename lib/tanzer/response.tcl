package provide tanzer::response 0.0.1
package require tanzer::message
package require TclOO

namespace eval ::tanzer::response {
    variable statuses

    array set statuses {
        200 "OK"
        206 "Partial Content"
        301 "Moved Permanently"
        400 "Bad Request"
        403 "Forbidden"
        404 "Not Found"
        405 "Method Not Allowed"
        415 "Unsupported Media Type"
        416 "Requested Range Not Satisfiable"
        500 "Internal Server Error"
    }
}

proc ::tanzer::response::lookup {status} {
    variable statuses

    if {[array get statuses $status] ne {}} {
        return $statuses($status)
    }

    return ""
}

::oo::class create ::tanzer::response {
    superclass ::tanzer::message
}

::oo::define ::tanzer::response constructor {_status args} {
    my variable version status headers data

    next

    set version $::tanzer::message::defaultVersion
    set status  $_status
    set headers {}
    set data    ""

    if {[llength $args] > 0} {
        my headers [lindex $args 0]
    }

    my header Server "$::tanzer::server::name/$::tanzer::server::version"
}

::oo::define ::tanzer::response method status {args} {
    my variable status

    switch -- [llength $args] 0 {
        return $status
    } 1 {
        return [set status [lindex $args 0]]
    }

    error "Invalid command invocation"
}

::oo::define ::tanzer::response method data {} {
    my variable data

    return $data
}

::oo::define ::tanzer::response method buffer {_data} {
    my variable data

    append data $_data
}

::oo::define ::tanzer::response method write {sock} {
    my variable version status headers data

    puts -nonewline $sock [format "%s %d %s\r\n" \
        $version $status [::tanzer::response::lookup $status]]

    set len [string length $data]

    if {$len > 0} {
        my header Content-Length $len
    }

    foreach {name value} $headers {
        puts -nonewline $sock "[::tanzer::message::field $name]: $value\r\n"
    }

    puts -nonewline $sock "\r\n"

    if {$len > 0} {
        puts -nonewline $sock $data
    }
}
