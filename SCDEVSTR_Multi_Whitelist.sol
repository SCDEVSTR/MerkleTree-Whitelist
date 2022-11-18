// Bu kontrat Bora Özenbirkan tarafından SCDEVSTR Lab çatısı altında yazılmıştır.
// Bu kontrat ile whitelist çalışma mekaniği incelenmiştir. Bitmiş ve yayına hazır bir NFT kontratı değildir.
// Çoklu whitelist ile farklı gruplara farklı ayrıcalıklar tanınmıştır. Tek whitelist için diğer kontrata bakmanızı öneririm.



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9; // Solidity sürümü

// Gerekli kütüphanelerimizi ekliyoruz
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/* 
    Bu kontratta diğer (tek whitelist) kontratta kullandığım açıklayıcı yorum satırlarını kullanmayacağım.
    Sadece çoklu whitelist nasıl kullanabiliriz farklı bir kaç kullanım şekline değineceğim.
*/
contract SCDEVSTR_Multi_Whitelist is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Çoklu whitelist için tek bir root yerine root dizisi oluşturuyoruz.
    bytes32[] public merkleRoots;

    // Diyelim ki farklı gruplara farklı mint fiyatı vereceğiz. Bunun için her grubun mint fiyatını içeren uint256 dizisi oluşturuyoruz.
    // root index'i ile mintPrices index'i eşleşecektir. Yani 3 numaralı root indexi içerisinde olan adreslerin mint fiyatı mintPrices[3]'de olacaktır.
    uint256[] public mintPrices;

    uint256 public publicMintPrice = 1 ether;   // Listede yer almayanlar için belirlediğimiz satış fiyatı

    constructor(bytes32[] memory _merkleRoot) ERC721("SCDEVSTR_Whitelist", "SDT") {
        merkleRoot = _merkleRoot;
    }



    // >< >< >< >< >< >< >< ><                                      >< >< >< >< >< >< >< >< //
    // >< >< >< >< >< ><       Güncelleme ve Yükleme Fonksiyonları        >< >< >< >< >< >< //
    // >< >< >< >< >< >< >< ><                                      >< >< >< >< >< >< >< >< //

    // Yeni bir listeyi mint fiyatı ile birlikte push ediyoruz. 
    // Tek push eden fonksiyon bu olduğu için root dizisi ile fiyat dizisinin indexlerinin aynı olduğundan eminiz.
    // 0x0sd921.. root'u ile 10000000000000000 sayısını girdi verirsem, verdiğim root içerisinde bulunan adresler 0.01 ETH fiyatla mint eder.
    // DİKKAT EDİN: Fiyatları kontrata girerken WEI cinsinden giriyoruz! WEI, GWEI, ETHER birimlerini bilmiyorsanız araştırın.
    // 0.01 ETH = 10000000000000000 WEI çeviri için bu siteyi kullanabilirsiniz: https://www.alchemy.com/gwei-calculator
    function pushMerkleRoot(bytes32 _merkleRoot, uint256 _mintPrice) public onlyOwner {
        merkleRoots.push(_merkleRoot);
        mintPrices.push(_mintPrice);
    }

    // Contratı yayınladıktan sonra root'umuzu güncellemek için gerekli fonksiyonumuz.
    // Hangi indexdeki root'u güncellemek istiyorsak indexi ile birlikte root'u gönderiyoruz.
    function updateMerkleRoot(uint256 _rootIndex, bytes32 _newRoot) external onlyOwner {
        merkleRoots[_rootIndex] = _newRoot;
    }

    // Aynı şekilde belirli bir root'a atadığımız mint fiyatını değiştirmek için de bir 
    function updateMintPrice(uint256 _index, uint256 _newPrice) external onlyOwner {
        mintPrices[_index] = _newPrice;
    }



    // >< >< >< >< >< >< >< ><                     >< >< >< >< >< >< >< >< //
    // >< >< >< >< >< ><       Mint Fonksiyonları        >< >< >< >< >< >< //
    // >< >< >< >< >< >< >< ><                     >< >< >< >< >< >< >< >< //

    // Tekli whitelist fonksiyonumuzdan farklı olarak, burada sadece adresin merkle tree'de olup olmadığını kontrol etmiyoruz.
    // Burada adres hangi kökte ise o köke karşılık olarak atadığımız mint fiyatını geri döndürüyoruz. returns (uint256)
    function mintCost(bytes32[] calldata _merkleProof) private view returns (uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        // for döngüsü ile tüm kökleri teker teker kontrol ediyoruz
        for (uint256 i = 0; i < merkleRoots.length; i++){
            
            // Eğer şuan kontrol ettiğimiz (i) kökteyse bu adres
            if (MerkleProof.verify(_merkleProof, merkleRoots[i], leaf)){
                
                // Bu listeye karlışık gelen yani aynı indexteki mint fiyatını geri döndürüyoruz.
                return mintPrices[i];
            }
        }
        
        // Eğer hiçbirinde yoksa, yani whitelist değilse liste-dışı mint fiyatını döndürüyoruz
        return publicMintPrice; 
    }

    // Herkese açık mint fonksiyonumuz
    function mint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public {
        require(_mintAmount == 3, "Mint amount can not exceed 1");  // adres başına mint miktarı sınırı
        require(msg.value >= mintCost(_merkleProof), "Invalid price input!"); // Gerekli mint fiyatını göndermezse işlem iptal

        // Kaç adet mintlemeyi arzulamışsa o kadar mintliyoruz. Tek tek mintliyoruz çünkü tek tek token ID artıyor.
        for (uint256 i = 0; i < _mintAmount; i++) {
            safeMint(_msgSender());
        }
    }

    /**
        NOT: 
        Eğer whitelist'e girenlere farklı mint fiyatlarından ziyade hepsine free mint vereceksininiz ama herkese farklı miktarlarda.
        Mesela bazılarına 1 adet, bazılarına 2, bazılarına 3, 5 adet free mint vermek istiyorsunuz.
        Bu durumda mintPrices yerine mintAmount adında bir dizi oluşturursunuz ve merkle ağacını kontrol eden fonksyionun döndürdüğü
        değer kaç ise o kadar mint yaptırırsınız. mint fonksiyonumuzun içindeki safeMint yapan for döngüsüne onu koyarsınız.

        Farklı şekillerde de kullanabilirsiniz. Bu tamamen sizin tasarım ve kodlama becerilerinize kalmış. 
        Farklı kontratları inceleyin, okuyun, remix üzerinden test edin. Sorularınızı önce kendini araştırıp çözmeye çalışın, 
        çözemezseniz SCDEVSTR Discord kanalında diğer arkadaşlardan yardım isteyin. Kolay gelsin!
    */



    // >< >< >< >< >< >< >< ><                        >< >< >< >< >< >< >< >< //
    // >< >< >< >< >< ><       Standart Fonksiyonlar        >< >< >< >< >< >< //
    // >< >< >< >< >< >< >< ><                        >< >< >< >< >< >< >< >< //

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
