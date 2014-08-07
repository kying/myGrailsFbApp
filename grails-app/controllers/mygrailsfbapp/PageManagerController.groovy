package mygrailsfbapp

class PageManagerController {
	
    def index() { 
		def u = new Person(fname: "Krystal");
		u.save();
		//render u.properties.fname
	}
}
