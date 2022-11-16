// Bu kontrat Bora Özenbirkan tarafından SCDEVSTR Lab çatısı altında yazılmıştır.
// Bu kontrat ile whitelist çalışma mekaniği incelenmiştir. Bitmiş ve yayına hazır bir NFT kontratı değildir.
// Bu kontratta tek bir adet whitelist kullanılmıştır. Çoklu whitelist kontratı farklıdır.



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9; // Solidity sürümü

// Gerekli kütüphanelerimizi ekliyoruz
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/* 
    Kontratımıza başlıyoruz. 
    SCDEVSTR adını verdiğimiz kontrat bir ERC721 kontrattır ve Ownable yani sahip olunabilir bir kontrattır. 
    Bu bizim yazıda da gördüğümüz onlyOwner Access Modifier'ını kullanmamızı sağlıyor.
*/
contract SCDEVSTR_Solo_Whitelist is ERC721, Ownable {
    // Counters kütüphanemizi kullanmak için gerekli deklerasyonu yapıyoruz.
    using Counters for Counters.Counter;

    /*
        _tokenIdCounter adında bir Counter, yani sayaç kullanıyoruz.
        Bu sayacı mintlenen NFT id'lerini saymak için kullanacağız.
        Sayaç yerine bir uint256 değişkeni de kullanabilirdik fakat bu tarz 1 kademe eksilip azalan sayaç değişkenleri için counter kullanmak en doğru yoldur. Hata yapma riskimizi ortadan kaldırır. Güvenlik önemleri yazımızda bunlara da değineceğiz.
    */
    Counters.Counter private _tokenIdCounter;

    // Root'umuzu ayarlıyoruz. Dilersek burada merkleRoot; diyerek boş olarak başlayıp, constructor kısmında da root'umuzu atayabiliriz. Zaten public olduğu için sonuç değişmez.
    bytes32 public merkleRoot = 0x235a431d30b7cc19b656d1ef14a6c5a257aab377a5854800c2d5446a1d3beb33

    constructor(bytes32 _merkleRoot) ERC721("SCDEVSTR_Whitelist", "SDT") {
        // Root'umuzu yukarıda merkleRoot; diyip geçmiş ve boş bırakmışsak, contratı yayınlarken constructor ile de bu şekilde atama yapabiliriz.
        merkleRoot = _merkleRoot;
    }

    // Contratı yayınladıktan sonra root'umuzu güncellemek için gerekli fonksiyonumuz
    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
    merkleRoot = _newRoot;
    }

    // Merkle proof'u kullanarak etkileşime giren adresin listede olup olmadığının kontrolünü yapan fonksiyonumuz
    function merkleCheck(bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // Whitelist'imiz ile mint fonksiyonumuz
    function whitelistMint(bytes32[] calldata _merkleProof) public {
        require(merkleCheck(_merkleProof), "You are not in the whitelist!");

        safeMint(_msgSender());
    }

    // Mint fonksiyonumuz internal olarak ayarladık ki dışarıdan kimse erişemesin
    function safeMint(address to) internal {
        // Sıradaki mint edilecek token ID'yi sayacımızdan alıyoruz.
        uint256 tokenId = _tokenIdCounter.current();
        
        // Sayacımızı 1 birim arttırıyoruz
        _tokenIdCounter.increment();

        // Ve girdi olarak verilen adrese sıradaki token ID'yi mintliyoruz.
        _safeMint(to, tokenId);
    }
}
