include { version_message; help_message } from './messages.nf'

def help_or_version(Map params, String version){
    // Show help message
    if (params.help){
        version_message(version)
        help_message()
        System.exit(0)
    }

    // Show version number
    if (params.version){
        version_message(version)
        System.exit(0)
    }
}

def check_mandatory_parameter(Map params, String parameter_name){
    if ( !params[parameter_name]){
        println "You must specify " + parameter_name
        System.exit(1)
    } else {
        return params[parameter_name]
    }
}

def check_optional_parameters(Map params, List parameter_names){
    if (parameter_names.collect{name -> params[name]}.every{param_value -> param_value == false}){
        println "You must specifiy at least one of these options: " + parameter_names.join(", ")
        System.exit(1)
    }
}

def check_parameter_value(String parameter_name, String value, List value_options){
    if (value_options.any{ it == value }){
        return value
    } else {
        println "The value for " + parameter_name + " must be one of " + value_options.join(", ")
        System.exit(1)
    }
}

def rename_params_keys(Map params_to_rename, Map old_and_new_names) {
    old_and_new_names.each{ old_name, new_name ->
        if (params_to_rename.containsKey(old_name))  {
            params_to_rename.put( new_name, params_to_rename.remove(old_name ) )
        }
    }
    return params_to_rename
}
