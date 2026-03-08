const {Client,GatewayIntentBits} = require("discord.js")
const fs = require("fs")

const client = new Client({
 intents:[
  GatewayIntentBits.Guilds,
  GatewayIntentBits.GuildMessages,
  GatewayIntentBits.MessageContent
 ]
})

const PREFIX = "."

function randomKey(){

 return "KEY-"+Math.random().toString(36).substring(2,10).toUpperCase()
}

client.once("ready",()=>{
 console.log("Bot online")
})

client.on("messageCreate",(msg)=>{

 if(msg.author.bot) return
 if(!msg.content.startsWith(PREFIX)) return

 const args = msg.content.slice(1).split(" ")
 const cmd = args[0]

 if(cmd==="taokey"){

  const key = randomKey()

  let data=[]

  if(fs.existsSync("keys.json")){
   data=JSON.parse(fs.readFileSync("keys.json"))
  }

  data.push({key:key})

  fs.writeFileSync("keys.json",JSON.stringify(data,null,2))

  msg.reply("Key created: "+key)

 }

})

client.login(process.env.DISCORD_TOKEN)
