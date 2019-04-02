require 'yaml'

#=======================================================================================================#
# General settings are conveniently set here before packaging.
SETTINGS = {
    :language => "english",
    :version => "0.0.1"
}
#=======================================================================================================#
# Strings section, this is to easily edit strings present in multiple places and for potential future
# translations.
ENGLISH_STRINGS = {
    :encrypted =>
%{This project is encrypted, RMSquad would be pretty useless here.},
    :initialize? => 
%{It looks like this project is not RMSquad initialized yet. Proceed?
(This is a non destructive operation, it simply adds files and deletes none)},
    :invalid_folder =>
%{It appears that the given folder was not a valid RPG Maker Vx Ace project folder.}
}

ALL_STRINGS = {
    "english" => ENGLISH_STRINGS
}

# All strings can be accessed as STRINGS[:key]
STRINGS = ALL_STRINGS[SETTINGS[:language]]
#=======================================================================================================#
module Utils
    def self.encrypted?(folder)
        Dir.entries(folder).include? "Game.rgss3a"
    end

    def self.initialized?(folder)
        root_content = Dir.entries(folder)
        ["RMSquad", "RMSquad.yml"].collect { |f| root_content.include?(f) }.all?
    end

    def self.valid_vx_ace?(folder)
        valid = true
        root_content = Dir.entries folder
        ["Audio", "Data", "Graphics", "System", "Game.rvproj2"].each { |f| valid &= root_content.include?(f) }
        if valid
            data_folder = File.join(folder, "Data")
            data_files = ["Actors", "Animations", "Armors", "Classes", "CommonEvents", "Enemies",
                          "Items", "MapInfos", "Scripts", "Skills", "States", "System", "Tilesets",
                          "Troops", "Weapons"]
            data_content = Dir.entries(data_folder)
            valid &= data_files.collect { |f| "#{f}.rvdata2" }.each { |f| data_content.include?(f) }.all?
        end
        valid
    end
end
#=======================================================================================================#
# Shoes definition for RMSquad Main Application
def launch(folder)
    # Make sure it's not an encrypted project
    if Utils.encrypted? folder
        alert STRINGS[:encrypted]
        return
    end

    # Make sure it's a valid vx ace folder
    unless Utils.valid_vx_ace? folder
        alert STRINGS[:invalid_folder]
        return
    end

    # Initialize project if it wasn't done
    unless Utils.initialized? folder
        if confirm STRINGS[:initialize?]

        else
            return
        end
    end

    # Main Application definition
    Shoes.app(title: "RMSquad | #{folder}", height: 768, width: 1024, resizable: true) do
    end
end
#=======================================================================================================#
# Shoes definition for RMSquad Launcher
Shoes.app(title: "RMSquad Launcher",  height: 320, width: 640) do
    background darkgray
    stack do
        flow do
            button "Open Folder" do
                folder = ask_open_folder
                launch folder
            end
        end
    end
end
#=======================================================================================================#