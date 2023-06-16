provider "azurerm" { 
  features {}
}

// resource "azurerm_resource_group" "example" {
//   name     = "example-resource-group"
//   location = "West Europe"
// }

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "east us"
  resource_group_name = "BHSDemo"
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = "BHSDemo"
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example-publicip"
  location            = "east us"
  resource_group_name = "BHSDemo"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = "east us"
  resource_group_name = "BHSDemo"

  ip_configuration {
    name                          = "example-ipc"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}
# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "east us"
    resource_group_name = "BHSDemo"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    tags = {
        environment = "Terraform Demo"
    }
}


resource "azurerm_virtual_machine" "example" {
  name                  = "example-vm"
  location              = "east us"
  resource_group_name   = "BHSDemo"
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "example-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "examplevm"
    admin_username = "adminuser"
    // admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true
  }

   admin_ssh_key {
        username       = "admineuser"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
	    
	connection {
        host = self.public_ip_address
        user = "azureuser"
        type = "ssh"
        private_key = tls_private_key.example_ssh.public_key_openssh
        timeout = "4m"
        agent = false
    }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello, World!'"
    ]
  }
}


# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "east us"
    resource_group_name       = "BHSDemo"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.example_ssh.private_key_pem 
    sensitive = true
}
