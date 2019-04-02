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
    :application_info =>
%{RMSquad #{SETTINGS[:version]} - #{SETTINGS[:language]}
Available under BSD 3-Clauses
by Superstroke

Built with Shoes (#{Shoes::RELEASE_NAME}, v#{Shoes::RELEASE_ID})

Icons by Material design
Available under Apache license version 2.0.},

    :close => %{Close Application},
    :encrypted =>
%{This project is encrypted, RMSquad would be pretty useless here.},
    :initialize? => 
%{It looks like this project is not RMSquad initialized yet. Proceed?
(This is a non destructive operation, it simply adds files and deletes none)},
    :info => %{What is this?},
    :invalid_folder =>
%{It appears that the given folder was not a valid RPG Maker Vx Ace project folder.},
    :open_folder => %{Open Folder}
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

class Locker
    def initialize
        @locked = true
    end
    def toggle!
        @locked = !@locked
    end
    def locked?
        @locked
    end
    def get_icon
        if locked?
          File.join("images", "lock.png")
        else
          File.join("images", "lock_open.png")
        end
    end
end
# Validate ensures the folder is ok for use
def validate(folder)
    # Make sure it's not an encrypted project
    if Utils.encrypted? folder
        alert STRINGS[:encrypted]
        return false
    end

    # Make sure it's a valid vx ace folder
    unless Utils.valid_vx_ace? folder
        alert STRINGS[:invalid_folder]
        return false
    end

    # Initialize project if it wasn't done
    unless Utils.initialized? folder
        if confirm STRINGS[:initialize?]
            Dir.mkdir(File.join(folder, "RMSquad"))
            File.open(File.join(folder, "RMSquad.yml"), "w") do |f|
            end
        else
            return false
        end
    end
    true
end

# Shoes definition for RMSquad Main Application
def launch(folder)
    return unless validate folder
    # Main Application definition
    Shoes.app(title: "RMSquad | #{File.basename(folder)}", height: 768, width: 1024, resizable: true) do
        @locker = Locker.new
        stack(margin: 10) do
            # Lock transaction
            flow(margin: 10) do
                background gainsboro
                @lock_icon = image File.join("images", "refresh.png")
                @lock_icon.path = @locker.get_icon
                @lock_checkbox = check { toggle_lock }
                @lock_checkbox.style margin: 5
                @lock_checkbox.checked = true
            end
        end

        def toggle_lock
            @locker.toggle!
            @lock_icon.path = @locker.get_icon
        end
    end
end
#=======================================================================================================#
# Shoes definition for RMSquad Launcher
Shoes.app(title: "RMSquad Launcher",  height: 320, width: 640) do
    background darkgray
    stack(margin: 40) do
        # Open a folder
        flow(margin: 10) do
            image File.join("images", "open.png"), margin: 10
            b = button STRINGS[:open_folder] { launch ask_open_folder }
            b.style height: 1.0, width: 0.75
        end
        # Release Info
        flow(margin: 10) do
            image File.join("images", "info.png"), margin: 10
            b = button STRINGS[:info] { alert STRINGS[:application_info] }
            b.style height: 1.0, width: 0.75
        end
        # Close (until I get a better button to put there)
        flow(margin: 10) do
            image File.join("images", "close.png"), margin: 10
            b = button STRINGS[:close] { exit() }
            b.style height: 1.0, width: 0.75
        end
    end
end
#=======================================================================================================#
