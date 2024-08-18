# Tardis

A collection of past CTFs to play and practice locally from the following projects/competitions:

- [**Curta**](https://curta.wtf) ([**repo**](https://github.com/waterfall-mkt/curta), [**𝕏**](https://x.com/curta_ctf)): a collection of fully on-chain puzzles on Ethereum and Base.

> [!NOTE]
> I want to add more CTFs, as well as a CLI and web app that runs locally to make everything more streamlined at some point.
> Please message [**@fiveoutofnine**](https://t.me/fiveoutofnine) on Telegram if you're interested in helping!

## Usage

This project uses [**Foundry**](https://github.com/foundry-rs/foundry) as its development framework.

### Installation

First, make sure you have Foundry installed. Then, run the following commands to clone the repo and install its dependencies:

```sh
git clone https://github.com/fiveoutofnine/tardis.git
cd tardis
forge install
```

Next, optionally install [**Huff**](https://github.com/huff-language/huff-rs) to solve the Huff puzzles:

```sh
curl -L get.huff.sh | bash
huffup
```

If that doesn't work, refer to the [**instructions on Huff's repo**](https://github.com/huff-language/huff-rs#installation).

### Solving

Each set of CTFs may require a different set-up to solve locally. Follow the instructions for each carefully:

| Project                        | Instructions                      |
| ------------------------------ | --------------------------------- |
| [**Curta**](https://curta.wtf) | [**Link**](./src/curta/README.md) |
