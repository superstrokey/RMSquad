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
    :cancel => %{Cancel},
    :close => %{Close Application},
    :launcher_encrypted =>
%{This project is encrypted, RMSquad would be pretty useless here.},
    :launcher_initialize? => 
%{It looks like this project is not RMSquad initialized yet. Proceed?
(This is a non destructive operation, it simply adds files and deletes none)},
    :launcher_info => %{What is this?},
    :launcher_invalid_folder =>
%{It appears that the given folder was not a valid RPG Maker Vx Ace project folder.},
    :launcher_open_folder => %{Open Folder},
    :settings_lfs => %{Use git LFS to manage assets?},
    :settings_data => %{Commit data files to repository?},
    :validate => %{Validate}
}

ALL_STRINGS = {
    "english" => ENGLISH_STRINGS
}

# All strings can be accessed as STRINGS[:key]
STRINGS = ALL_STRINGS[SETTINGS[:language]]

#=======================================================================================================#
class SettingsWrapper
    attr_accessor :commit_data
    attr_accessor :use_lfs

    def initialize
        @commit_data = false
        @use_lfs = false
    end

    def dump
        YAML.dump({"commit_data" => @commit_data, "use_lfs" => @use_lfs})
    end

    def load(data)
        settings = YAML.load(data)
        @commit_data = settings["commit_data"]
        @use_lfs = settings["use_lfs"]
    end
end
#=======================================================================================================#
class VxProject
    attr_reader :folder

    def initialize(folder)
        @folder = folder
    end

    def encrypted?
        Dir.entries(@folder).include? "Game.rgss3a"
    end

    def initialized?
        root_content = Dir.entries(@folder)
        ["RMSquad", "RMSquad.yml"].collect { |f| root_content.include?(f) }.all?
    end

    def valid_vx_ace?
        valid = true
        root_content = Dir.entries @folder
        ["Audio", "Data", "Graphics", "System", "Game.rvproj2"].each { |f| valid &= root_content.include?(f) }
        if valid
            data_folder = File.join(@folder, "Data")
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
class Lock
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

#=======================================================================================================#

GITIGNORE_DATA =
%{
Data/
System/
Game*
}

GITATTRIBUTES_LFS =
%{
#Image
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
*.gif filter=lfs diff=lfs merge=lfs -text

#Audio
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text

#Video
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
}

def setup(project)
    if project.initialized?
        launch project.folder
        return
    end

    if confirm STRINGS[:launcher_initialize?]
        Dir.mkdir(File.join(project.folder, "RMSquad"))
        Shoes.app(title: "RMSquad Project Configuration",  height: 320, width: 640) do 
            stack(margin: 10) do
                settings = SettingsWrapper.new
                flow(margin: 10) do
                    @check_use_lfs = check
                    para STRINGS[:settings_lfs]
                end
                flow(margin: 10) do
                    @check_commit_data = check
                    para STRINGS[:settings_data]
                end
                flow(margin: 10) do
                    button STRINGS[:cancel] { close() }
                    button STRINGS[:validate] do
                        settings.commit_data = @check_commit_data.checked?
                        settings.use_lfs = @check_use_lfs.checked?
                        File.open(File.join(project.folder, "RMSquad.yml"), "w") do |f|
                            f.write(settings.dump)
                        end
                        File.open(File.join(project.folder, ".gitattributes"), "a+") do |f|
                            if settings.use_lfs
                                f.write(GITATTRIBUTES_LFS)
                            end
                        end
                        File.open(File.join(project.folder, ".gitignore"), "a+") do |f|
                            unless settings.commit_data
                                f.write(GITIGNORE_DATA)
                            end
                        end
                        launch project.folder
                        close()
                    end
                end
            end
        end
    end
end

#=======================================================================================================#
# Validate ensures the folder is ok for use
def validate(folder)
    project = VxProject.new folder
    # Make sure it's not an encrypted project
    if project.encrypted?
        alert STRINGS[:launcher_encrypted]
        return
    end

    # Make sure it's a valid vx ace folder
    unless project.valid_vx_ace?
        alert STRINGS[:launcher_invalid_folder]
        return
    end
    # Setup project for use
    setup project
end

#=======================================================================================================#
# Shoes definition for RMSquad Main Application
def launch(folder)
    # Main Application definition
    Shoes.app(title: "RMSquad | #{File.basename(folder)}", height: 768, width: 1024, resizable: true) do
        @lock = Lock.new
        stack(margin: 10) do
            # Lock transaction
            flow(margin: 10) do
                background gainsboro
                @lock_icon = image File.join("images", "refresh.png")
                @lock_icon.path = @lock.get_icon
                @lock_checkbox = check { toggle_lock }
                @lock_checkbox.style margin: 5
                @lock_checkbox.checked = true
            end
        end

        def toggle_lock
            @lock.toggle!
            @lock_icon.path = @lock.get_icon
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
            b = button STRINGS[:launcher_open_folder] { validate ask_open_folder }
            b.style height: 1.0, width: 0.75
        end
        # Release Info
        flow(margin: 10) do
            image File.join("images", "info.png"), margin: 10
            b = button STRINGS[:launcher_info] { alert STRINGS[:launcher_application_info] }
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
