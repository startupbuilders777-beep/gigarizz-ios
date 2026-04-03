import Foundation
import SwiftUI

// MARK: - Dating Apps Photo Packs

extension PhotoPack {
    /// Tinder-optimized pack
    static let tinderPack = PhotoPack(
        name: "Tinder Dominator",
        description: "Bold, attention-grabbing photos optimized for Tinder's algorithm.",
        icon: "flame.fill",
        platform: .tinder,
        photoTypes: [
            PackPhotoType(
                name: "Swipe-Right Headshot",
                description: "Bright, bold primary photo that stops the scroll",
                icon: "hand.tap.fill",
                aiPrompt: "High-impact dating headshot, bright vibrant colors, strong eye contact, " +
                    "10/10 smile, perfect lighting, close crop, Tinder-optimized portrait",
                importance: .critical
            ),
            PackPhotoType(
                name: "Lifestyle Flex",
                description: "Full body showing off your best outfit and vibe",
                icon: "figure.stand",
                aiPrompt: "Stylish full body photo, trendy outfit, urban setting, cool confident " +
                    "stance, bright natural lighting, fashion-forward dating photo",
                importance: .critical
            ),
            PackPhotoType(
                name: "Fun Energy",
                description: "Action shot that shows you're fun to be around",
                icon: "party.popper.fill",
                aiPrompt: "Fun energetic lifestyle photo, laughing candid moment, bright colorful " +
                    "setting, social atmosphere, warm genuine expression, dynamic composition",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Mystery Shot",
                description: "Looking away or profile view - creates intrigue",
                icon: "eye.slash.fill",
                aiPrompt: "Artistic profile portrait, looking away into distance, moody atmospheric " +
                    "lighting, cinematic feel, mysterious attractive vibe, editorial photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Adventure",
                description: "Shows you're not boring - outdoor/travel shot",
                icon: "mountain.2.fill",
                aiPrompt: "Adventure outdoor portrait, hiking or beach or mountain, athletic casual " +
                    "wear, golden hour sunlight, scenic natural backdrop, adventurous spirit",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Night Out",
                description: "Well-dressed, social, night scene",
                icon: "moon.stars.fill",
                aiPrompt: "Night out portrait, upscale bar or restaurant, well-dressed smart casual, " +
                    "warm ambient lighting, confident relaxed pose, nightlife photography",
                importance: .bonus
            )
        ],
        gradient: [DesignSystem.Colors.tinder, .pink],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )

    /// Hinge-optimized pack
    static let hingePack = PhotoPack(
        name: "Hinge Charmer",
        description: "Genuine, conversation-starting photos that match Hinge's authentic vibe.",
        icon: "heart.fill",
        platform: .hinge,
        photoTypes: [
            PackPhotoType(
                name: "Warm Welcome",
                description: "Approachable, warm primary photo",
                icon: "face.smiling.inverse",
                aiPrompt: "Warm approachable portrait, genuine smile, soft natural lighting, simple " +
                    "clean background, inviting expression, conversation-starting dating photo",
                importance: .critical
            ),
            PackPhotoType(
                name: "Passion Project",
                description: "Doing something you're passionate about",
                icon: "paintpalette.fill",
                aiPrompt: "Person engaged in a creative hobby, painting or cooking or playing music, " +
                    "focused passionate expression, natural setting, candid authentic moment",
                importance: .critical
            ),
            PackPhotoType(
                name: "With Friends",
                description: "Shows you're valued by others",
                icon: "person.2.fill",
                aiPrompt: "Social gathering photo, laughing with friends, genuine happy moment, warm " +
                    "restaurant or outdoor setting, natural candid, social proof dating photo",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Dressed Up",
                description: "Show you clean up nice",
                icon: "tshirt.fill",
                aiPrompt: "Well-dressed portrait, smart casual or semi-formal outfit, elegant " +
                    "setting, confident posture, clean sharp styling, attractive put-together look",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Outdoor Casual",
                description: "Relaxed outdoor shot in nature or city",
                icon: "leaf.fill",
                aiPrompt: "Casual outdoor portrait, park or garden or urban rooftop, relaxed natural " +
                    "pose, golden hour light, comfortable authentic vibe, lifestyle photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Quirky/Fun",
                description: "Shows your personality and humor",
                icon: "theatermask.and.paintbrush.fill",
                aiPrompt: "Fun personality photo, playful expression, interesting unique setting, " +
                    "shows sense of humor, creative composition, memorable dating photo",
                importance: .bonus
            )
        ],
        gradient: [DesignSystem.Colors.hinge, Color(hex: "8B7355")],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )

    /// Bumble-optimized pack
    static let bumblePack = PhotoPack(
        name: "Bumble Standout",
        description: "Friendly, approachable photos that make women want to message first.",
        icon: "bolt.fill",
        platform: .bumble,
        photoTypes: [
            PackPhotoType(
                name: "Friendly Face",
                description: "Approachable, kind primary photo",
                icon: "face.smiling",
                aiPrompt: "Friendly approachable headshot, warm kind smile, bright natural lighting, " +
                    "soft background, trustworthy genuine expression, women-friendly dating photo",
                importance: .critical
            ),
            PackPhotoType(
                name: "Dog/Pet Lover",
                description: "With a pet - instant conversation starter",
                icon: "pawprint.fill",
                aiPrompt: "Person with a cute dog in a park, genuine happy smile, natural sunlight, " +
                    "warm heartfelt moment with pet, lifestyle photography, conversation-starting photo",
                importance: .critical
            ),
            PackPhotoType(
                name: "Cooking/Foodie",
                description: "In the kitchen or at a great restaurant",
                icon: "fork.knife",
                aiPrompt: "Person cooking in a modern kitchen or enjoying food at a nice restaurant, " +
                    "genuine smile, warm lighting, shows domestic skill and taste, lifestyle photo",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Active Lifestyle",
                description: "Hiking, biking, or sport - shows healthy living",
                icon: "figure.run",
                aiPrompt: "Active lifestyle portrait, hiking trail or cycling or yoga, athletic casual " +
                    "wear, natural outdoor setting, healthy energetic vibe, fitness photography",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Culture Shot",
                description: "Museum, concert, or bookstore - shows depth",
                icon: "books.vertical.fill",
                aiPrompt: "Cultural outing portrait, art museum or bookstore or concert, thoughtful " +
                    "engaged expression, interesting setting, shows intellectual depth, lifestyle photo",
                importance: .recommended
            ),
            PackPhotoType(
                name: "Laughing Candid",
                description: "Mid-laugh genuine joy moment",
                icon: "face.smiling.inverse",
                aiPrompt: "Genuine laughing candid portrait, mid-laugh natural joy, bright warm " +
                    "setting, authentic happy moment, not posed, natural photography captures real personality",
                importance: .bonus
            )
        ],
        gradient: [DesignSystem.Colors.bumble, .orange],
        tier: .plus,
        estimatedTime: "~45s",
        photoCount: 6
    )
}
