<?php
	$username = 'austinpreneur';
	$password = 'Iphone5@';

	$api = new API($username,$password);
	$api->handleCommand();
	
////////////////////////////////////////////////////////////////////////////////

class API
{
	private $pdo;

	function __construct($username,$password)
	{

		try{
			//Create database object
			$this->pdo = new PDO('mysql:host=austinpreneur.db.10211992.hostedresource.com;dbname=austinpreneur',$username,$password,array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8"));
			$this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
			//echo 'created database<br>';
		}
		catch(PDOException $e){
			echo 'ERROR: '.$e->getMessage();
		}
	}
	
	function handleCommand(){
		// Figure out which command the client sent and let the corresponding
		// method handle it. If the command is unknown, then exit with an error
		// message.

		if (isset($_POST['cmd']))
		{
			switch (trim($_POST['cmd']))
			{
				case 'upload_photo':$this->upload_photo();return;
			}
		}
	}

	function upload_photo(){
		$photo = $_POST['photo'];
		$filename = $_POST['filename'];
		
		echo $filename;
		echo "/".$photo."/";
		
		$target_path = "/user_images/";
		$target_path = $target_path . basename( $_FILES['filename']['name']); 
		
		if(move_uploaded_file($_FILES['filename']['tmp_name'], $target_path)) {
    		echo "The file ".  basename( $_FILES['filename']['name'])." has been uploaded";
		} else{
    		echo "There was an error uploading the file, please try again!". $_FILES['filename']['error'];
		}
		
		echo $_FILES["photo"]["size"];
		/*
		$imagedata = imagecreatefrompng($photo);
		ob_start();
		imagepng($imagedata);
		$stringdata = ob_get_contents(); // read from buffer
		ob_end_clean(); // delete buffer
		$zdata = gzdeflate($stringdata);
		
		echo $imagedata;
		
		$file = '../user_images/'.$filename;
		$fp = fopen($file, 'wb');
		//ImagePNG($photo, $file); 
		fwrite($fp, $_FILES["photo"]);
		*/
		
		/*
		$FTP_HOST = "50.62.70.1";
		$FTP_USER = "dwmc9817";
		$FTP_PW   = "Iphone5@";

		$conn_id = ftp_connect($FTP_HOST) or die ("Can't connect to FTP Server : $FTP_HOST"); ;

		$login_result = ftp_login($conn_id, $FTP_USER, $FTP_PW) or die ("Can't login to FTP Server : $FTP_HOST");;

		if (ftp_fput($conn_id, $file, $fp, FTP_ASCII)) {
		    echo "Successfully uploaded $file\n";
		} else {
  		  	echo "There was a problem while uploading $file\n";
		}
		
		//ftp_close($conn_id);
		//fclose($fp);
		*/
	}
}

?>