#!/usr/bin/env python3
"""Example project script demonstrating custom sandbox tools."""

import sys
from rich.console import Console
from rich.panel import Panel

console = Console()

def main():
    console.print(Panel.fit(
        "[bold green]OpenCode Custom Sandbox Environment[/bold green]\n"
        "[cyan]Rich styling and custom Python dependencies are active![/cyan]",
        title="Example Project"
    ))
    return 0

if __name__ == "__main__":
    sys.exit(main())
