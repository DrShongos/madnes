import io
import os 
import argparse
import sys
import subprocess

def compile(args):
    # Odin does not automatically create paths, so we need to create it manually
    target_exists = os.path.exists("target")
    if not target_exists:
        os.makedirs("target")
    
    # Compile first, because the compiler does not allow directly passing arguments to the program.
    compile_process = subprocess.run(["odin", "build", "src/", "-out:target/madnes"])

    # Runs only if the compilation process didn't fail
    if compile_process.returncode == 0:
        subprocess.run(["./target/madnes", args.rom])
    

def run(args):
    parser = argparse.ArgumentParser()
    parser.add_argument("--rom", required=True, help="--rom file.nes")

    if len(args) == 0:
        return

    command = parser.parse_args(args)
    compile(command)
    


if __name__ == "__main__":
    args = sys.argv
    args.pop(0)
    run(args)
