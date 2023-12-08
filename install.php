<?php
class Colors { //Colors src: http://www.if-not-true-then-false.com/2010/php-class-for-coloring-php-command-line-cli-scripts-output-php-output-colorizing-using-bash-shell-colors/
    private $foreground_colors = array();
    private $background_colors = array();

    public function __construct() {
        // Set up shell colors
        $this->foreground_colors['black'] = '0;30';
        $this->foreground_colors['dark_gray'] = '1;30';
        $this->foreground_colors['blue'] = '0;34';
        $this->foreground_colors['light_blue'] = '1;34';
        $this->foreground_colors['green'] = '0;32';
        $this->foreground_colors['light_green'] = '1;32';
        $this->foreground_colors['cyan'] = '0;36';
        $this->foreground_colors['light_cyan'] = '1;36';
        $this->foreground_colors['red'] = '0;31';
        $this->foreground_colors['light_red'] = '1;31';
        $this->foreground_colors['purple'] = '0;35';
        $this->foreground_colors['light_purple'] = '1;35';
        $this->foreground_colors['brown'] = '0;33';
        $this->foreground_colors['yellow'] = '1;33';
        $this->foreground_colors['light_gray'] = '0;37';
        $this->foreground_colors['white'] = '1;37';

        $this->background_colors['black'] = '40';
        $this->background_colors['red'] = '41';
        $this->background_colors['green'] = '42';
        $this->background_colors['yellow'] = '43';
        $this->background_colors['blue'] = '44';
        $this->background_colors['magenta'] = '45';
        $this->background_colors['cyan'] = '46';
        $this->background_colors['light_gray'] = '47';
    }

    // Returns colored string
    public function getColoredString($string, $foreground_color = null, $background_color = null) {
        $colored_string = "";

        // Check if given foreground color found
        if (isset($this->foreground_colors[$foreground_color])) {
            $colored_string .= "\033[" . $this->foreground_colors[$foreground_color] . "m";
        }
        // Check if given background color found
        if (isset($this->background_colors[$background_color])) {
            $colored_string .= "\033[" . $this->background_colors[$background_color] . "m";
        }

        // Add string and end coloring
        $colored_string .=  $string . "\033[0m";

        return $colored_string;
    }

    // Returns all foreground color names
    public function getForegroundColors() {
        return array_keys($this->foreground_colors);
    }

    // Returns all background color names
    public function getBackgroundColors() {
        return array_keys($this->background_colors);
    }
}

$useForce = false;
if (isset($argv[1]) && $argv[1] == '-f') {
    $useForce = true;
}

$c = new Colors;

function __g($str) { global $c; return $c->getColoredString($str, 'green'); }
function __r($str) { global $c; return $c->getColoredString($str, 'red'); }

define("DS", DIRECTORY_SEPARATOR);
define("HOME", rtrim(getenv("HOME"), DS));
chdir(dirname(__FILE__));
$cwd = rtrim(getcwd(), DS);

function create_link($path, $name) {
    global $cwd, $useForce;
    echo __g("Linking $name...");
    try {
        if (file_exists($path)) {
            if (!file_exists(HOME.DS.$path) || $useForce) {
                if (file_exists(HOME.DS.$path)) {
                    $new_name = HOME.DS.$path.".bak_dotfiles_installer";
                    while (file_exists($new_name)) {
                        $new_name .= ".copy";
                    }
                    rename(HOME.DS.$path, $new_name);
                }
                symlink($cwd.DS.$path, HOME.DS.$path);
                echo __g("DONE\n");
            } else {
                throw new RuntimeException ("$name files already exist");
            }
        } else {
            throw new RuntimeException ("$name files appear to be missing");
        }
    } catch (RuntimeException $e) {
        echo __r("FAIL (".$e->getMessage().")\n");
    }
}

//Setup symlinks
$entries = glob(".*");
foreach ($entries as $entry) {
    if (in_array($entry, array(".", "..", ".git"))) continue;
    create_link($entry, ucfirst(strtolower(substr($entry, 1))));
}

//Install kickstart
echo __g("Cloning Neovim Kickstart...\n");
passthru("git clone git@github.com:raxbg/kickstart.nvim.git ~/.config/nvim", $ret_val);
if ($ret_val == 0) {
    echo __g("Kickstart installed succcessfully\n");
} else {
    echo __r("Failed to install Kickstart! Aborting script...\n");
    exit;
}

//Install Tmux Plugin Manager
echo __g("Cloning Tmux Plugin Manager...\n");
passthru("git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm", $ret_val);
if ($ret_val == 0) {
    echo __g("TPM installed succcessfully\n");
} else {
    echo __r("Failed to install TPM! Aborting script...\n");
    exit;
}

//Install Vundle
echo __g("Cloning Vundle...\n");
passthru("git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim", $ret_val);
if ($ret_val == 0) {
    echo __g("Vundle installed succcessfully\n");
} else {
    echo __r("Failed to install Vundle! Aborting script...\n");
    exit;
}

//Install Vim plugins
echo __g("Installing Vim plugins\n");
passthru('vim -c "PluginInstall" -c ":qa"', $ret_val);
if ($ret_val == 0) {
    echo __g("Vim plugins installed succcessfully\n");
} else {
    echo __r("Failed to install Vim plugins! Aborting script...\n");
    exit;
}
