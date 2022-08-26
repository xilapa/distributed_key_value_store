# KV

 Distributed key-value store from Elixir [getting started](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html#our-first-project "getting started") tutorial.

### Run locally
#### Start the sever
On windows
`iex.bat -S mix`
Other systems 
`iex -S mix`

#### Connect to it
Open the terminal and type `telnet 127.0.0.1 4040` and send commands like
	
```shell
CREATE itens_to_buy
OK

PUT itens_to_buy pencil 1
OK

PUT itens_to_buy erasor 3
OK

GET itens_to_buy pencil
1
OK

DELETE itens_to_buy eggs
OK
```
