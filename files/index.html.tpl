<!doctype html>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/css/bootstrap.min.css" crossorigin="anonymous">
<script src="https://code.jquery.com/jquery-3.2.1.min.js" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.11.0/umd/popper.min.js"  crossorigin="anonymous"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/js/bootstrap.min.js"  crossorigin="anonymous"></script>
<script src="http://guy.ukwest.cloudapp.azure.com:8000/socket.io/socket.io.js"></script>

<div class="container" >
 <div class="jumbotron">
	<h1 class="" >Chat host: ${hostname} </h1>
	<br>
	<div class="panel panel-primary ">
   
	<div id="messages" data-spy="scroll" ></div>
	</div>
	</div>
<br>  
	<div class="panel panel-primary">
    <div class="panel-heading panel-primary">Send A Message</div>
    <div class="panel-body panel-primary">
      <div class="input-group">
	  <br>
        <input id="name" class="form-control .input-sm" placeholder="Name">
        <br>
        <textarea id="message" class="form-control custom-control" rows=3 style="resize:none" placeholder="Message" ></textarea>
        <span id="send" class="input-group-addon btn btn-primary">Send</span>
      </div>
    </div> 
	
    
</div>
</div>
<script crossorigin="anonymous">
    var socket = io('http://guy.ukwest.cloudapp.azure.com:8000');

    $(() => {
        $("#send").click(()=>{
            var message = { name: $("#name").val(), message: $("#message").val()}
            postMessage(message)
        })
        getMessages()
    })

    socket.on('message',addMessage)


    function addMessage(message){
        $("#messages").append(`<h4> $${message.name} </h4> <p> $${message.message} </p>`)
    }

    function getMessages() {
        $.get('http://guy.ukwest.cloudapp.azure.com:8000/messages', (data) => {
            data.forEach(addMessage);
        })
    }

    function postMessage(message) {
        $.post('http://guy.ukwest.cloudapp.azure.com:8000/messages', message)
    }
</script>